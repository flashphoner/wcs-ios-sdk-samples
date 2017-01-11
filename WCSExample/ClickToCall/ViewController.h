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

@interface ViewController : UIViewController<UITextFieldDelegate>

@property UIScrollView *scrollView;
@property UIView *contentView;

@property UITextField *connectUrl;
@property WCSTextInputView *callee;
@property UILabel *callStatus;
@property UIButton *callButton;

@end

