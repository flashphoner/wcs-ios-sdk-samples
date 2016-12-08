//
//  ViewController.h
//  WCSApiExample
//
//  Created by user on 24/11/2015.
//  Copyright © 2015 user. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <FPWCSApi2/RTCEAGLVideoView.h>
#import "WCSViews.h"
#import "WCSLocalVideoControl.h"
#import "WCSRemoteVideoControl.h"

@interface ViewController : UIViewController

@property UIScrollView *scrollView;
@property UIView *contentView;
@property UILabel *connectStatus;
@property UIButton *startButton;
@property UIView *settingsButtonContainer;
@property UIButton *localSettingsButton;
@property UIButton *remoteSettingsButton;
@property UITextField *urlInput;
@property WCSDoubleVideoView *videoView;
@property WCSLocalVideoControlView *localControl;
@property WCSRemoteVideoControlView *remoteControl;

@end

