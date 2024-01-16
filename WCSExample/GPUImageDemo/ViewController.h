//
//  ViewController.h
//  WCSApiExample
//
//  Created by flashphoner on 24/11/2015.
//  Copyright © 2015 flashphoner. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <WebRTC/RTCMTLVideoView.h>
#import <GPUImage/GPUImage.h>

@interface ViewController : UIViewController<UITextFieldDelegate, RTCVideoViewDelegate>

@property UIScrollView *scrollView;
@property UIView *contentView;

@property UITextField *connectUrl;
@property UILabel *connectionStatus;
@property UIButton *connectButton;

@property UILabel *publishStreamLabel;
@property UITextField *localStreamName;
@property UILabel *localStreamStatus;
@property UIButton *publishButton;
@property UIButton *beautyButton;
@property BOOL beautifyEnabled;

@property UILabel *playStreamLabel;
@property UITextField *remoteStreamName;
@property UILabel *remoteStreamStatus;
@property UIButton *playButton;

@property UIView *videoContainer;
@property(nonatomic) UIView<RTCVideoRenderer> *localNativeDisplay;
@property(nonatomic) GPUImageView *localDisplay;
@property(nonatomic) UIView<RTCVideoRenderer> *remoteDisplay;

@property NSMutableArray *localDisplayConstraints;
@property NSMutableArray *remoteDisplayConstraints;

@end

