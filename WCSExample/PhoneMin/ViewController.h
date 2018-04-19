//
//  ViewController.h
//  WCSApiExample
//
//  Created by user on 24/11/2015.
//  Copyright © 2015 user. All rights reserved.
//

#import "WCSViews.h"
#import <UIKit/UIKit.h>
#import <FPWCSApi2/RTCEAGLVideoView.h>
#import <JSONModel/JSONModel.h>

@interface ViewController : UIViewController<UITextFieldDelegate>

@property UIScrollView *scrollView;
@property UIView *contentView;

@property UITextField *connectUrl;
@property WCSTextInputView *sipLogin;
@property WCSTextInputView *sipAuthName;
@property WCSTextInputView *sipPassword;
@property WCSTextInputView *sipDomain;
@property WCSTextInputView *sipOutboundProxy;
@property WCSTextInputView *sipPort;
@property WCSSwitchView *sipRegRequired;
@property UILabel *connectionStatus;
@property UIButton *connectButton;
@property WCSTextInputView *inviteParameters;
@property WCSTextInputView *callee;
@property UILabel *callStatus;
@property UIButton *callButton;
@property UIButton *holdButton;
@property WCSTextInputView *dtmf;
@property UIButton *dtmfButton;
@end

