//
//  CameraVideoCapturer.swift
//  ImageOverlaySwift
//
//  Created by Andrey Stepanov on 06.05.2021.
//  Copyright © 2021 flashphoner. All rights reserved.
//

import Foundation
import WebRTC
import AVFoundation

class CameraVideoCapturer: RTCCameraVideoCapturer {
    let kNanosecondsPerSecond = 1000000000

    var device: AVCaptureDevice?
 
    override init() {
        super.init()
        self.device = self.cameraWithPosition(position: .back)
    }
    
    private override init(delegate: RTCVideoCapturerDelegate) {
        super.init(delegate: delegate)
        self.device = self.cameraWithPosition(position: .back)
    }
    
    private func cameraWithPosition(position: AVCaptureDevice.Position) -> AVCaptureDevice? {
        let devices = AVCaptureDevice.devices(for: AVMediaType.video)
        var _device: AVCaptureDevice?
        for d in devices {
            if d.position == position {
                _device = d as? AVCaptureDevice
                break
            }
        }
        return _device
    }
    
    func startCapture() {
        self.startCapture(with: device!, format: device!.activeFormat, fps: 30)
    }
    
    func scale(velocity: CGFloat) {
        guard let device = self.device else { return }
        
        let maxZoomFactor = device.activeFormat.videoMaxZoomFactor
        let pinchVelocityDividerFactor: CGFloat = 15
        
        
        do {
            try device.lockForConfiguration()
            defer { device.unlockForConfiguration() }

            let desiredZoomFactor = device.videoZoomFactor + atan2(velocity, pinchVelocityDividerFactor)
            device.videoZoomFactor = max(1.0, min(desiredZoomFactor, maxZoomFactor))
        } catch {
            print(error)
        }
    }
    
}

extension CameraVideoCapturer: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        if (CMSampleBufferGetNumSamples(sampleBuffer) != 1 || !CMSampleBufferIsValid(sampleBuffer) ||
            !CMSampleBufferDataIsReady(sampleBuffer)) {
          return;
        }

        let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
        if (pixelBuffer == nil) {
            return;
        }
        
        let rtcPixelBuffer = RTCCVPixelBuffer(pixelBuffer: pixelBuffer!)
        let timeStampNs = CMTimeGetSeconds(CMSampleBufferGetPresentationTimeStamp(sampleBuffer)) *
            Float64(kNanosecondsPerSecond)
        
        
        let videoFrame = RTCVideoFrame(buffer: rtcPixelBuffer,
                                       rotation: ._90,
                                       timeStampNs: Int64(timeStampNs))
        self.delegate?.capturer(self, didCapture: videoFrame)
    }
    
    func captureOutput(_ output: AVCaptureOutput, didDrop sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        let droppedReason = CMGetAttachment(sampleBuffer,
                                            key: kCMSampleBufferAttachmentKey_DroppedFrameReason,
                                            attachmentModeOut: nil)
        
        let nsDroppedReason = droppedReason as? NSString
        let swiftDroppedReason = nsDroppedReason as String?
        
        if let swiftDroppedReason = swiftDroppedReason {
            NSLog("Dropped sample buffer. Reason: " + swiftDroppedReason)
        }
        else {
            NSLog("Dropped sample buffer. Reason: unknown")
        }
    }
}
