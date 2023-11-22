//
//  RTCFileVideoCapturer.h
//  GPUImageDemo
//
//  Created by flashphoner on 18.09.2020.
//  Copyright © 2020 flashphoner. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <WebRTC/RTCVideoCapturer.h>
#import <GPUImageVideoCamera.h>
#import <GPUImage/GPUImage.h>
#import <FPWCSApi2/FPWCSApi2Model.h>
/**
 * RTCVideoCapturer that reads buffers from file.
 *
 * Per design, the file capturer can only be run once and once stopped it cannot run again.
 * To run another file capture session, create new instance of the class.
 */
@interface GPUImageVideoCapturer : RTCVideoCapturer<FPWCSVideoCapturer>

- (void)processNewFrame:(GPUImageRawDataOutput*)rawDataOutput;
@end
