//
//  ViewController.h
//  WCSApiExample
//
//  Created by flashphoner on 24/11/2015.
//  Copyright © 2015 flashphoner. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <WebRTC/RTCMTLVideoView.h>

@interface ViewController : UIViewController<UITextFieldDelegate, RTCVideoViewDelegate>

@property UIScrollView *scrollView;
@property UIView *contentView;

@property UITextField *connectUrl;
@property UILabel *connectionStatus;
@property UIButton *connectButton;

@property UIView *player1Container;
@property UITextField *player1StreamName;
@property UILabel *player1Status;
@property UIButton *player1Button;

@property UIView *player2Container;
@property UITextField *player2StreamName;
@property UILabel *player2Status;
@property UIButton *player2Button;

@property UIView *videoContainer;
@property(nonatomic) RTCMTLVideoView *player1Display;
@property(nonatomic) RTCMTLVideoView *player2Display;

@property NSMutableArray *player1DisplayConstraints;
@property NSMutableArray *player2DisplayConstraints;

@end

