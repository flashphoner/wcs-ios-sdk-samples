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
    
    var overlayImage: CIImage?
 
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
    
    func updateOverlayImage(_ image:CIImage) {
        self.overlayImage = image;
    }
    
    func startCapture() {
        var currentFormat = device!.activeFormat
        for format in device!.formats {
            let dimensions = CMVideoFormatDescriptionGetDimensions(format.formatDescription)
            if (dimensions.width == 640) {
                currentFormat = format
                print(currentFormat.debugDescription)
                break
            }
    
        }
        self.startCapture(with: device!, format: currentFormat, fps: 30)
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
        
        if (overlayImage != nil) {
            let inputImage = CIImage.init(cvImageBuffer: pixelBuffer!);
            let combinedFilter = CIFilter(name: "CISourceOverCompositing")!
            combinedFilter.setValue(inputImage, forKey: "inputBackgroundImage")
            combinedFilter.setValue(overlayImage, forKey: "inputImage")

            let outputImage = combinedFilter.outputImage!
            let tmpcontext = CIContext(options: nil)
            tmpcontext.render(outputImage, to: pixelBuffer!, bounds: outputImage.extent, colorSpace: CGColorSpaceCreateDeviceRGB())

        }
        let rtcPixelBuffer = RTCCVPixelBuffer(pixelBuffer: pixelBuffer!)
        let timeStampNs = CMTimeGetSeconds(CMSampleBufferGetPresentationTimeStamp(sampleBuffer)) *
            Float64(kNanosecondsPerSecond)
        
        let videoFrame = RTCVideoFrame(buffer: rtcPixelBuffer,
                                       rotation: ._90,
                                       timeStampNs: Int64(timeStampNs))
        self.delegate?.capturer(self, didCapture: videoFrame)
    }
    
    func convertCIImageToCGImage(inputImage: CIImage) -> CGImage! {
        let context = CIContext(options: nil)
        return context.createCGImage(inputImage, from: inputImage.extent)
    }
    
    func pixelBufferFromCGImage(image: CGImage) -> CVPixelBuffer {
        var pxbuffer: CVPixelBuffer? = nil
        let options: NSDictionary = [:]

        let width =  image.width
        let height = image.height
        let bytesPerRow = image.bytesPerRow

        let dataFromImageDataProvider = CFDataCreateMutableCopy(kCFAllocatorDefault, 0, image.dataProvider!.data)
        let x = CFDataGetMutableBytePtr(dataFromImageDataProvider)

        CVPixelBufferCreateWithBytes(
            kCFAllocatorDefault,
            width,
            height,
            kCVPixelFormatType_32ARGB,
            x!,
            bytesPerRow,
            nil,
            nil,
            options,
            &pxbuffer
        )
        return pxbuffer!;
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
