//
//  ViewController.m
//  WCSApiExample
//
//  Created by flashphoner on 24/11/2015.
//  Copyright © 2015 flashphoner. All rights reserved.
//

#import "WCSUtil.h"
#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <FPWCSApi2/FPWCSApi2.h>

@interface ViewController ()

@end

@implementation ViewController

FPWCSApi2Session *session;
FPWCSApi2Call *call;
UIAlertController *alert;


- (void)viewDidLoad {
    [WCSViewUtil updateBackgroundColor:self];
    [super viewDidLoad];
    [self setupViews];
    [self setupLayout];
    [self onDisconnected];
    NSLog(@"Did load views");
}

//connect
- (FPWCSApi2Session *)connect {
    FPWCSApi2SessionOptions *options = [[FPWCSApi2SessionOptions alloc] init];
    options.urlServer = _connectUrl.text;
    options.appKey = @"clickToCallApp";
    NSError *error;
    session = [FPWCSApi2 createSession:options error:&error];
    if (error) {
        UIAlertController * alert = [UIAlertController
                                     alertControllerWithTitle:@"Failed to connect"
                                     message:error.localizedDescription
                                     preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction* okButton = [UIAlertAction
                                   actionWithTitle:@"Ok"
                                   style:UIAlertActionStyleDefault
                                   handler:^(UIAlertAction * action) {
                                       [self onDisconnected];
                                   }];
        
        [alert addAction:okButton];
        [self presentViewController:alert animated:YES completion:nil];
        return nil;
    }
    
    [session on:kFPWCSSessionStatusEstablished callback:^(FPWCSApi2Session *rSession){
        [self changeConnectionStatus:[rSession getStatus]];
        [self onConnected:rSession];
    }];
    
    [session on:kFPWCSSessionStatusDisconnected callback:^(FPWCSApi2Session *rSession){
        [self changeConnectionStatus:[rSession getStatus]];
        [self onDisconnected];
        session = nil;
    }];
    
    [session on:kFPWCSSessionStatusFailed callback:^(FPWCSApi2Session *rSession){
        [self changeConnectionStatus:[rSession getStatus]];
        [self onDisconnected];
        session = nil;
    }];
    
    [session connect];
    return session;
}

- (FPWCSApi2Call *)call {
    FPWCSApi2CallOptions *options = [[FPWCSApi2CallOptions alloc] init];
    options.callee = _callee.input.text;
    options.localConstraints = [[FPWCSApi2MediaConstraints alloc] initWithAudio:YES video:NO];
    NSError *error;
    call = [session createCall:options error:&error];
    if (!call) {
        UIAlertController * alert = [UIAlertController
                                     alertControllerWithTitle:@"Failed to create call"
                                     message:error.localizedDescription
                                     preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction* okButton = [UIAlertAction
                                   actionWithTitle:@"Ok"
                                   style:UIAlertActionStyleDefault
                                   handler:^(UIAlertAction * action) {
                                       [self onDisconnected];
                                   }];
        
        [alert addAction:okButton];
        [self presentViewController:alert animated:YES completion:nil];
        return nil;
    }

    [call on:kFPWCSCallStatusBusy callback:^(FPWCSApi2Call *call){
        [self changeCallStatus:call];
        [self onDisconnected];
    }];
    
    [call on:kFPWCSCallStatusFailed callback:^(FPWCSApi2Call *call){
        [self changeCallStatus:call];
        [self onDisconnected];
    }];
    
    [call on:kFPWCSCallStatusRing callback:^(FPWCSApi2Call *call){
        [self changeCallStatus:call];
        [self onHangup];
    }];
    
    [call on:kFPWCSCallStatusHold callback:^(FPWCSApi2Call *call){
        [self changeCallStatus:call];
    }];
    
    [call on:kFPWCSCallStatusEstablished callback:^(FPWCSApi2Call *call){
        [self changeCallStatus:call];
        [self onHangup];
    }];
    
    [call on:kFPWCSCallStatusFinish callback:^(FPWCSApi2Call *call){
        [self changeCallStatus:call];
        [self onDisconnected];
    }];
    
    [call call];
    return call;
}

//session and stream status handlers
- (void)onConnected:(FPWCSApi2Session *)session {
    [self onHangup];
    [self call];
}

- (void)onDisconnected {
    [_callButton setTitle:@"CALL" forState:UIControlStateNormal];
    [self changeViewState:_callButton enabled:YES];
}

- (void)onHangup {
    [_callButton setTitle:@"HANGUP" forState:UIControlStateNormal];
    [self changeViewState:_callButton enabled:YES];
}


- (void)callButton:(UIButton *)button {
    [self changeViewState:button enabled:NO];
    if ([button.titleLabel.text isEqualToString:@"HANGUP"]) {
        if (call) {
            [call hangup];
        }
    } else {
        if (session) {
            [self call];
        } else {
            [self connect];
        }
    }
}


//status handlers
- (void)changeConnectionStatus:(kFPWCSSessionStatus)status {
    _callStatus.text = [NSString stringWithFormat:@"Connection: %@", [FPWCSApi2Model sessionStatusToString:status]];
    switch (status) {
        case kFPWCSSessionStatusFailed:
            _callStatus.textColor = [UIColor redColor];
            break;
        case kFPWCSSessionStatusEstablished:
        case kFPWCSSessionStatusRegistered:
            _callStatus.textColor = [UIColor greenColor];
            break;
        default:
            _callStatus.textColor = [UIColor darkTextColor];
            break;
    }
}

- (void)changeCallStatus:(FPWCSApi2Call *)call {
    _callStatus.text = [NSString stringWithFormat:@"Call: %@", [FPWCSApi2Model callStatusToString:[call getStatus]]];
    switch ([call getStatus]) {
        case kFPWCSCallStatusFailed:
            _callStatus.textColor = [UIColor redColor];
            break;
        case kFPWCSCallStatusEstablished:
        case kFPWCSCallStatusRing:
            _callStatus.textColor = [UIColor greenColor];
            break;
        default:
            _callStatus.textColor = [UIColor darkTextColor];
            break;
    }
}

//button state helper
- (void)changeViewState:(UIView *)button enabled:(BOOL)enabled {
    button.userInteractionEnabled = enabled;
    if (enabled) {
        button.alpha = 1.0;
    } else {
        button.alpha = 0.5;
    }
}

//user interface views and layout
- (void)setupViews {
    //views main->scroll->content-videoContainer-display
    _scrollView = [[UIScrollView alloc] init];
    _scrollView.translatesAutoresizingMaskIntoConstraints = NO;
    _scrollView.scrollEnabled = YES;
    
    _contentView = [[UIView alloc] init];
    _contentView.translatesAutoresizingMaskIntoConstraints = NO;
    
    _connectUrl = [WCSViewUtil createTextField:self];
    _callee = [[WCSTextInputView alloc] init];
    _callee.label.text = @"Callee";
    _callStatus = [WCSViewUtil createLabelView];
    _callButton = [WCSViewUtil createButton:@"CALL"];
    [_callButton addTarget:self action:@selector(callButton:) forControlEvents:UIControlEventTouchUpInside];

    
    
    [self.contentView addSubview:_connectUrl];
    [self.contentView addSubview:_callee];
    [self.contentView addSubview:_callStatus];
    [self.contentView addSubview:_callButton];
    
    [self.scrollView addSubview:_contentView];
    [self.view addSubview:_scrollView];
    
    //set default values
    _connectUrl.text = @"wss://demo.flashphoner.com:8443/";
    _callee.input.text = @"1001";
}

- (void)setupLayout {
    NSDictionary *views = @{
                            @"connectUrl": _connectUrl,
                            @"callee": _callee,
                            @"callStatus":_callStatus,
                            @"callButton":_callButton,
                            @"contentView": _contentView,
                            @"scrollView": _scrollView
                            };
    
    NSNumber *videoHeight = @240;
    //custom videoHeight for pads
    if ( UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ) {
        NSLog(@"Set video container height for pads");
        videoHeight = @480;
    }
    
    NSDictionary *metrics = @{
                              @"buttonHeight": @30,
                              @"statusHeight": @30,
                              @"labelHeight": @20,
                              @"inputFieldHeight": @30,
                              @"videoHeight": videoHeight,
                              @"vSpacing": @15,
                              @"hSpacing": @30
                              };
   
    //constraint helpers
    NSLayoutConstraint* (^setConstraintWithItem)(UIView*, UIView*, UIView*, NSLayoutAttribute, NSLayoutRelation, NSLayoutAttribute, CGFloat, CGFloat) =
    ^NSLayoutConstraint* (UIView *dst, UIView *with, UIView *to, NSLayoutAttribute attr1, NSLayoutRelation relation, NSLayoutAttribute attr2, CGFloat multiplier, CGFloat constant) {
        NSLayoutConstraint *constraint =[NSLayoutConstraint constraintWithItem:with attribute:attr1 relatedBy:relation toItem:to attribute:attr2 multiplier:multiplier constant:constant];
        [dst addConstraint:constraint];
        return constraint;
    };
    
    void (^setConstraint)(UIView*, NSString*, NSLayoutFormatOptions) = ^(UIView *view, NSString *constraint, NSLayoutFormatOptions options) {
        [view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:constraint options:options metrics:metrics views:views]];
    };
    
    setConstraint(_connectUrl, @"V:[connectUrl(inputFieldHeight)]", 0);

    setConstraint(_contentView, @"H:|-hSpacing-[connectUrl]-hSpacing-|", 0);
    setConstraint(_contentView, @"H:|-hSpacing-[callee]-hSpacing-|",0);
    setConstraint(_contentView, @"H:|-hSpacing-[callStatus]-hSpacing-|",0);
    setConstraint(_contentView, @"H:|-hSpacing-[callButton]-hSpacing-|",0);
    
    setConstraint(self.contentView, @"V:|-50-[connectUrl]-vSpacing-[callee]-vSpacing-[callStatus]-vSpacing-[callButton]-vSpacing-|", 0);
    
    //content view width
    setConstraintWithItem(self.view, _contentView, self.view, NSLayoutAttributeWidth, NSLayoutRelationEqual, NSLayoutAttributeWidth, 1.0, 0);
    
    //position content and scroll views
    setConstraint(self.view, @"V:|[contentView]|", 0);
    setConstraint(self.view, @"H:|[contentView]|", 0);
    setConstraint(self.view, @"V:|[scrollView]|", 0);
    setConstraint(self.view, @"H:|[scrollView]|", 0);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(BOOL) textFieldShouldReturn:(UITextField *)textField{
    [textField resignFirstResponder];
    return YES;
}

@end
