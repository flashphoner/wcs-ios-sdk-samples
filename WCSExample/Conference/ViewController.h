//
//  ViewController.h
//  WCSApiExample
//
//  Created by flashphoner on 24/11/2015.
//  Copyright © 2015 flashphoner. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WCSViews.h"
#import <WebRTC/RTCMTLVideoView.h>

@interface ViewController : UIViewController<UITextFieldDelegate, RTCVideoViewDelegate>

@property UIScrollView *scrollView;
@property UIView *contentView;

@property UITextField *connectUrl;
@property WCSTextInputView *connectLogin;
@property UILabel *connectionStatus;
@property UIButton *connectButton;

@property WCSTextInputView *joinRoomName;
@property UILabel *joinStatus;
@property UIButton *joinButton;

@property UIView *player1Container;
@property(nonatomic) RTCMTLVideoView *player1Display;
@property NSMutableArray *player1DisplayConstraints;
@property UILabel *player1Login;

@property UIView *player2Container;
@property(nonatomic) RTCMTLVideoView *player2Display;
@property NSMutableArray *player2DisplayConstraints;
@property UILabel *player2Login;


@property UIView *localVideoContainer;
@property(nonatomic) RTCMTLVideoView *localDisplay;
@property NSMutableArray *localDisplayConstraints;
@property UILabel *localStatus;
@property WCSSwitchView *muteAudio;
@property WCSSwitchView *muteVideo;
@property UIButton *publishButton;

@property UITextView  *messageHistory;
@property UITextField *messageBody;
@property UIButton *sendButton;


@end

