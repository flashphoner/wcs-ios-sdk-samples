//
//  ViewController.h
//  WCSApiExample
//
//  Created by flashphoner on 24/11/2015.
//  Copyright © 2015 flashphoner. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <WebRTC/RTCEAGLVideoView.h>
@import AVFoundation;
@import AVKit;

@interface ViewController : UIViewController<UITextFieldDelegate, RTCVideoViewDelegate, AVAssetResourceLoaderDelegate>

@property UIScrollView *scrollView;
@property UIView *contentView;

@property UITextField *connectUrl;
@property UILabel *status;
@property UIButton *startButton;

@property UITextView *recordLink;

@property UIView *videoContainer;
@property(nonatomic) RTCEAGLVideoView *remoteDisplay;

@property NSMutableArray *remoteDisplayConstraints;

@property (strong, nonatomic) AVPlayerViewController *playerViewController;
@property (strong, nonatomic) AVPlayer *player;

@end

