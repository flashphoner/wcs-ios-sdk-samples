//
//  ViewController.h
//  WCSApiExample
//
//  Created by user on 24/11/2015.
//  Copyright © 2015 user. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <FPWCSApi2/RTCEAGLVideoView.h>

@interface ViewController : UIViewController<UITextFieldDelegate, RTCEAGLVideoViewDelegate>

@property UIScrollView *scrollView;
@property UIView *contentView;

@property UITextField *connectUrl;
@property UILabel *connectionStatus;
@property UIButton *connectButton;

@property UITextField *localStreamName;
@property UILabel *localStreamStatus;
@property UIButton *publishButton;

@property UITextField *remoteStreamName;
@property UILabel *remoteStreamStatus;
@property UIButton *playButton;

@property UIView *videoContainer;
@property(nonatomic) RTCEAGLVideoView *localDisplay;
@property(nonatomic) RTCEAGLVideoView *remoteDisplay;

@property NSMutableArray *localDisplayConstraints;
@property NSMutableArray *remoteDisplayConstraints;

@end

