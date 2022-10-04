
import Foundation
import WebRTC
import AVFoundation
import GPUImage
import FPWCSApi2Swift

class CameraVideoCapturer: RTCVideoCapturer , FPWCSVideoCapturer {
    
    let kNanosecondsPerSecond = 1000000000

    var camera:Camera?
    var filter: BasicOperation?
    var capturing = false;
    fileprivate var gpuImageConsumer:GPUImageConsumer!
    
    override init() {
        super.init()
        self.gpuImageConsumer = GPUImageConsumer(capturer: self)
    }
    
    func applyFilter(_ filter: BasicOperation?) {
        self.filter = filter
        
        if let cam = self.camera, capturing {
            cam.removeAllTargets()
            
            self.gpuImageConsumer.removeSourceAtIndex(0)
            
            if let fil = self.filter {
                cam --> fil --> self.gpuImageConsumer
            } else {
                cam --> self.gpuImageConsumer
            }
        }
        
    }
    
    func startCapture(with device: AVCaptureDevice!, format: AVCaptureDevice.Format!, fps: Int) {
        if (self.camera != nil && self.camera?.inputCamera.localizedName != device.localizedName) {
            stopCapture()
            camera = nil;
        }
        
        if (self.camera == nil) {
            do {
                let camera = try Camera(sessionPreset:.vga640x480, cameraDevice: device, orientation: .portrait, captureAsYUV: false)
                self.camera = camera
            } catch {
                fatalError("Could not initialize rendering pipeline: \(error)")
            }
        }
        
        self.capturing = true
        
        applyFilter(self.filter)
        
        self.camera?.startCapture()
    }
    
    func lockCameraOrientation() {
    }
    
    func unlockCameraOrientation() {
    }
    
    func stopCapture() {
        camera?.removeAllTargets()
        self.gpuImageConsumer.removeSourceAtIndex(0)
        
        camera?.stopCapture()
        self.capturing = false
    }

    func captureOutput(_ pixelBuffer: CVPixelBuffer, time: CMTime) {
        let rtcPixelBuffer = RTCCVPixelBuffer(pixelBuffer: pixelBuffer)
        let videoFrame = RTCVideoFrame(buffer: rtcPixelBuffer,
                                       rotation: ._90,
                                       timeStampNs: Int64(CMTimeGetSeconds(time) * Float64(kNanosecondsPerSecond)))
        self.delegate?.capturer(self, didCapture: videoFrame)
    }
}

fileprivate class GPUImageConsumer :  ImageConsumer {

    public let sources = SourceContainer()
    public let maximumInputs:UInt = 1
    
    var capturer: CameraVideoCapturer;
    
    private var previousFrameTime = CMTime.negativeInfinity
    
    public init(capturer: CameraVideoCapturer) {
        self.capturer = capturer
        
    }
    
    public func newTextureAvailable(_ texture:Texture, fromSourceIndex:UInt) {
        // Ignore still images and other non-video updates (do I still need this?)
        guard let frameTime = texture.timingStyle.timestamp?.asCMTime else { return }
        // If two consecutive times with the same value are added to the movie, it aborts recording, so I bail on that case
        guard (frameTime != previousFrameTime) else {
            return
        }
        
        var pixelBufferFromPool:CVPixelBuffer? = nil
        
        let pixelBufferStatus = CVPixelBufferCreate(kCFAllocatorDefault, texture.texture.width, texture.texture.height, kCVPixelFormatType_32BGRA, nil, &pixelBufferFromPool);
        
        guard let pixelBuffer = pixelBufferFromPool, (pixelBufferStatus == kCVReturnSuccess) else {
            return
            
        }
        CVPixelBufferLockBaseAddress(pixelBuffer, [])
       
        renderIntoPixelBuffer(pixelBuffer, texture:texture)
        capturer.captureOutput(pixelBuffer, time: frameTime)
        CVPixelBufferUnlockBaseAddress(pixelBuffer, [])
    }
    
    func renderIntoPixelBuffer(_ pixelBuffer:CVPixelBuffer, texture:Texture) {
        guard let pixelBufferBytes = CVPixelBufferGetBaseAddress(pixelBuffer) else {
            print("Could not get buffer bytes")
            return
        }
        let mtlTexture = texture.texture;
        guard let commandBuffer = sharedMetalRenderingDevice.commandQueue.makeCommandBuffer() else { fatalError("Could not create command buffer on image rendering.")}
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()
        
        let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
        let region = MTLRegionMake2D(0, 0, mtlTexture.width, mtlTexture.height)
        mtlTexture.getBytes(pixelBufferBytes, bytesPerRow: bytesPerRow, from: region, mipmapLevel: 0)
    }
}
