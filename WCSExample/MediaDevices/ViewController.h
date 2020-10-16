//
//  ViewController.h
//  WCSApiExample
//
//  Created by flashphoner on 24/11/2015.
//  Copyright © 2015 flashphoner. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <WebRTC/RTCEAGLVideoView.h>
#import <CoreAudio/CoreAudioTypes.h>
#import <AVFoundation/AVFoundation.h>
#import "WCSViews.h"
#import "WCSLocalVideoControl.h"
#import "WCSRemoteVideoControl.h"

@interface ViewController : UIViewController

@property UIScrollView *scrollView;
@property UIView *contentView;
@property UILabel *connectStatus;
@property UILabel *micLevel;
@property UIButton *testButton;
@property UIButton *startButton;
@property WCSSwitchView *lockCameraOrientation;
@property WCSSwitchView *useLoudSpeaker;
@property UIView *settingsButtonContainer;
@property UIButton *localSettingsButton;
@property UIButton *remoteSettingsButton;
@property UITextField *urlInput;
@property WCSDoubleVideoView *videoView;
@property WCSLocalVideoControlView *localControl;
@property WCSRemoteVideoControlView *remoteControl;
@property AVAudioRecorder *recorder;
@property NSTimer *levelTimer;
@property double lowPassResults;

@end

