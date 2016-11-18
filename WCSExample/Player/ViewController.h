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
@property UILabel *playStreamLabel;
@property UITextField *remoteStreamName;
@property UILabel *status;
@property UIButton *startButton;

@property UIView *videoContainer;
@property(nonatomic) RTCEAGLVideoView *remoteDisplay;

@property NSMutableArray *remoteDisplayConstraints;

@end

