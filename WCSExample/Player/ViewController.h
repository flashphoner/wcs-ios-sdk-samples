//
//  ViewController.h
//  WCSApiExample
//
//  Created by flashphoner on 24/11/2015.
//  Copyright © 2015 flashphoner. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <WebRTC/RTCEAGLVideoView.h>
#import <WebRTC/RTCMTLVideoView.h>

@interface ViewController : UIViewController<UITextFieldDelegate, RTCVideoViewDelegate>

@property UIScrollView *scrollView;
@property UIView *contentView;

@property UITextField *connectUrl;
@property UILabel *playStreamLabel;
@property UITextField *remoteStreamName;
@property UILabel *status;
@property UIButton *startButton;
@property UIButton *fullscreenButton;
@property bool fullscreen;

@property UIView *videoContainer;
@property(nonatomic) UIView<RTCVideoRenderer> *remoteDisplay;

@property NSMutableArray *remoteDisplayConstraints;

@end

