//
//  ViewController.h
//  WCSApiExample
//
//  Created by flashphoner on 24/11/2015.
//  Copyright © 2015 flashphoner. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <WebRTC/RTCEAGLVideoView.h>

@interface ViewController : UIViewController<UITextFieldDelegate, RTCVideoViewDelegate>

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

