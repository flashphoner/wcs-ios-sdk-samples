//
//  RTCFileVideoCapturer.m
//  TwoWayStreaming
//
//  Created by flashphoner on 18.09.2020.
//  Copyright © 2020 flashphoner. All rights reserved.
//

#import "GPUImageVideoCapturer.h"

#import <WebRTC/RTCLogging.h>
#import <WebRTC/RTCVideoFrameBuffer.h>
#import <WebRTC/RTCCVPixelBuffer.h>

@implementation GPUImageVideoCapturer {
  AVAssetReader *_reader;
  AVAssetReaderTrackOutput *_outTrack;
  BOOL _capturerStopped;
  CMTime _lastPresentationTime;
  dispatch_queue_t _frameQueue;
}

- (void)startCaptureWithDevice:(AVCaptureDevice *)device
                        format:(AVCaptureDeviceFormat *)format
                           fps:(NSInteger)fps {
}

- (void)stopCapture {
  _capturerStopped = YES;
}

- (void)lockCameraOrientation { 
}


- (void)unlockCameraOrientation { 
}


- (void)processNewFrame:(GPUImageRawDataOutput*) rawDataOutput {
    CVPixelBufferRef sourcePixelBuffer = [self convertImage:rawDataOutput];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        RTCCVPixelBuffer *rtcPixelBuffer = [[RTCCVPixelBuffer alloc] initWithPixelBuffer:sourcePixelBuffer];
        NSTimeInterval timeStampSeconds = CACurrentMediaTime();
        int64_t timeStampNs = lroundf(timeStampSeconds * NSEC_PER_SEC);
        RTCVideoFrame *videoFrame = [[RTCVideoFrame alloc] initWithBuffer:rtcPixelBuffer rotation:RTCVideoRotation_0 timeStampNs:timeStampNs];
        [self.delegate capturer:self didCaptureVideoFrame:videoFrame];
        
        CVPixelBufferRelease(sourcePixelBuffer);
    });
}

#pragma mark - Private
- (CVPixelBufferRef)convertImage:(GPUImageRawDataOutput *) rawDataOutput {
        
    NSInteger bytesPerRow = rawDataOutput.bytesPerRowInOutput;
    NSInteger sourceWidth = rawDataOutput.maximumOutputSize.width;
    NSInteger sourceHeight = rawDataOutput.maximumOutputSize.height;
    
    NSDictionary *options = @{(id)kCVPixelBufferIOSurfacePropertiesKey : @{}};
    CVPixelBufferRef pixelBuffer = NULL;
    CVReturn status = CVPixelBufferCreate(kCFAllocatorDefault, sourceWidth, sourceHeight, kCVPixelFormatType_420YpCbCr8BiPlanarFullRange, (__bridge CFDictionaryRef)(options), &pixelBuffer);
    NSParameterAssert(status == kCVReturnSuccess && pixelBuffer != NULL);
        
    CVPixelBufferLockBaseAddress(pixelBuffer, 0);
    size_t width = CVPixelBufferGetWidth(pixelBuffer);
    size_t height = CVPixelBufferGetHeight(pixelBuffer);
    size_t wh = width * height;

    size_t width0 = CVPixelBufferGetWidthOfPlane(pixelBuffer, 0);
    size_t height0 = CVPixelBufferGetHeightOfPlane(pixelBuffer, 0);
    size_t bpr0 = CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 0);

    size_t width1 = CVPixelBufferGetWidthOfPlane(pixelBuffer, 1);
    size_t height1 = CVPixelBufferGetHeightOfPlane(pixelBuffer, 1);
    size_t bpr1 = CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 1);
        
    unsigned char *bufY = malloc(wh);
    unsigned char *bufUV = malloc(wh/2);
     
    size_t offset,p;
     
    int r,g,b,y,u,v;
    int a=255;
    [rawDataOutput lockFramebufferForReading];
    uint8_t *tempAddress = rawDataOutput.rawBytesForImage;
    
    for (int row = 0; row < height; ++row) {
      for (int col = 0; col < width; ++col) {
        //
        offset = ((width * row) + col);
        p = offset*4;
        //
        b = tempAddress[p + 0];
        g = tempAddress[p + 1];
        r = tempAddress[p + 2];
        a = tempAddress[p + 3];
        //
        y = 0.299*r + 0.587*g + 0.114*b;
        u = -0.1687*r - 0.3313*g + 0.5*b + 128;
        v = 0.5*r - 0.4187*g - 0.0813*b + 128;
        //
        bufY[offset] = y;
        bufUV[(row/2)*width + (col/2)*2] = u;
        bufUV[(row/2)*width + (col/2)*2 + 1] = v;
      }
    }
    [rawDataOutput unlockFramebufferAfterReading];

    
    uint8_t *yPlane = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 0);
    memset(yPlane, 0x80, height0 * bpr0);
    for (int row=0; row<height0; ++row) {
      memcpy(yPlane + row*bpr0, bufY + row*width0, width0);
    }
    uint8_t *uvPlane = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 1);
    memset(uvPlane, 0x80, height1 * bpr1);
    for (int row=0; row<height1; ++row) {
      memcpy(uvPlane + row*bpr1, bufUV + row*width, width);
    }
        
    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
    free(bufY);
    free(bufUV);
    
    return pixelBuffer;
}

- (void)dealloc {
  [self stopCapture];
}

@end
