//
//  ViewController.h
//  WCSApiExample
//
//  Created by user on 24/11/2015.
//  Copyright © 2015 user. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <FPWCSApi2/RTCEAGLVideoView.h>
@import AVFoundation;
@import AVKit;

@interface ViewController : UIViewController<UITextFieldDelegate, RTCEAGLVideoViewDelegate, AVAssetResourceLoaderDelegate>

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

