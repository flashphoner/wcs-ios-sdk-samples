//
//  ViewController.h
//  WCSApiExample
//
//  Created by flashphoner on 24/11/2015.
//  Copyright © 2015 flashphoner. All rights reserved.
//

#import "WCSViews.h"
#import <UIKit/UIKit.h>
#import <WebRTC/RTCMTLVideoView.h>

@interface ViewController : UIViewController<UITextFieldDelegate>

@property UIScrollView *scrollView;
@property UIView *contentView;

@property WCSDoubleVideoView *videoView;

@property UITextField *connectUrl;
@property UILabel *connectionStatus;
@property UIButton *connectButton;

@end

