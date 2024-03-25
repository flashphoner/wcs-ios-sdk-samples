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
    return [self connectWithOptions:options];
    
}

- (FPWCSApi2Session *)connectWithToken {
    FPWCSApi2SessionOptions *options = [[FPWCSApi2SessionOptions alloc] init];
    options.authToken = _authToken.input.text;
    return [self connectWithOptions:options];
}

- (FPWCSApi2Session *)connectWithOptions:(FPWCSApi2SessionOptions *)options {
    options.urlServer = _connectUrl.text;
    options.keepAlive = true;
    options.sipRegisterRequired = _sipRegRequired.control.isOn;
    options.sipLogin = _sipLogin.input.text;
    options.sipAuthenticationName = _sipAuthName.input.text;
    options.sipPassword = _sipPassword.input.text;
    options.sipDomain = _sipDomain.input.text;
    options.sipOutboundProxy = _sipOutboundProxy.input.text;
    options.sipPort = [NSNumber numberWithInteger: [_sipPort.input.text integerValue]];
    options.appKey = @"defaultApp";
    NSError *error;
    if (!options.sipLogin.length || !options.sipAuthenticationName.length || !options.sipPassword.length ||
        !options.sipDomain.length || !options.sipOutboundProxy.length || options.sipPort.integerValue == 0) {
        UIAlertController * alert = [UIAlertController
                                     alertControllerWithTitle:@"All Sip Credentials is required"
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
        _authToken.input.text = [rSession getAuthToken];
        [self changeConnectionStatus:[rSession getStatus]];
        [self onConnected:rSession];
        if (!_sipRegRequired.control.isOn) {
                [self changeViewState:_callButton enabled:YES];
        }
    }];
    
    [session on:kFPWCSSessionStatusRegistered callback:^(FPWCSApi2Session *rSession){
        [self changeConnectionStatus:[rSession getStatus]];
        [self onConnected:rSession];
        if (_sipRegRequired) {
            [self changeViewState:_callButton enabled:YES];
        }
    }];
    
    [session on:kFPWCSSessionStatusDisconnected callback:^(FPWCSApi2Session *rSession){
        [self changeConnectionStatus:[rSession getStatus]];
        [self onDisconnected];
    }];
    
    [session on:kFPWCSSessionStatusFailed callback:^(FPWCSApi2Session *rSession){
        [self changeConnectionStatus:[rSession getStatus]];
        [self onDisconnected];
    }];
    
    [session onIncomingCallCallback:^(FPWCSApi2Call *rCall) {
        call = rCall;
        
        [call on:kFPWCSCallStatusBusy callback:^(FPWCSApi2Call *call){
            [self changeCallStatus:call];
            [self toCallState];
        }];
        
        [call on:kFPWCSCallStatusFailed callback:^(FPWCSApi2Call *call){
            [self changeCallStatus:call];
            [self toCallState];
        }];
        
        [call on:kFPWCSCallStatusRing callback:^(FPWCSApi2Call *call){
            [self changeCallStatus:call];
            [self toHangupState];
        }];
        
        [call on:kFPWCSCallStatusHold callback:^(FPWCSApi2Call *call){
            [self changeCallStatus:call];
            [self changeViewState:_holdButton enabled:YES];
        }];
        
        [call on:kFPWCSCallStatusEstablished callback:^(FPWCSApi2Call *call){
            [self changeCallStatus:call];
            _useLoudSpeaker.control.userInteractionEnabled = YES;
            [self toHangupState];
            [self changeViewState:_holdButton enabled:YES];
        }];
        
        [call on:kFPWCSCallStatusFinish callback:^(FPWCSApi2Call *call){
            [self changeCallStatus:call];
            _useLoudSpeaker.control.userInteractionEnabled = NO;
            [_useLoudSpeaker.control setOn: NO animated:YES];
            [self toCallState];
            [self dismissViewControllerAnimated:YES completion:nil];
        }];

        alert = [UIAlertController
                                     alertControllerWithTitle:[NSString stringWithFormat:@"Incoming call from '%@'", [rCall getCallee]]
                                     message:error.localizedDescription
                                     preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction* answerButton = [UIAlertAction
                                   actionWithTitle:@"Answer"
                                   style:UIAlertActionStyleDefault
                                   handler:^(UIAlertAction * action) {
                                       [call answer];
                                   }];
        
        [alert addAction:answerButton];
        UIAlertAction* hangupButton = [UIAlertAction
                                       actionWithTitle:@"Hangup"
                                       style:UIAlertActionStyleDefault
                                       handler:^(UIAlertAction * action) {
                                           [call hangup];
                                       }];
        
        [alert addAction:hangupButton];
        [self presentViewController:alert animated:YES completion:nil];
    }];
    
    [session connect];
    return session;
}

- (FPWCSApi2Call *)call {
    FPWCSApi2Session *session = [FPWCSApi2 getSessions][0];
    FPWCSApi2CallOptions *options = [[FPWCSApi2CallOptions alloc] init];
    NSString *parameters = _inviteParameters.input.text;
    if (parameters && [parameters length] > 0) {
        NSError* err = nil;
        parameters = [parameters stringByReplacingOccurrencesOfString:@"”" withString:@"\""];
        NSMutableDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:[parameters dataUsingEncoding:NSUTF8StringEncoding] options:0 error:&err];
        if (err) {
            NSLog(@"Error converting JSON Invite parameters to dictionary %@, JSON %@", err, parameters);
        } else {
            options.inviteParameters = dictionary;
        }
    }
    options.callee = _callee.input.text;
    //used for only recv audio
//    options.localConstraints = [[FPWCSApi2MediaConstraints alloc] initWithAudio:NO video:NO];
//    options.remoteConstraints = [[FPWCSApi2MediaConstraints alloc] initWithAudio:YES video:NO];
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
                                       [self toCallState];
                                   }];
        
        [alert addAction:okButton];
        [self presentViewController:alert animated:YES completion:nil];
        return nil;
    }

    [call on:kFPWCSCallStatusBusy callback:^(FPWCSApi2Call *call){
        [self changeCallStatus:call];
        [self toCallState];
    }];
    
    [call on:kFPWCSCallStatusFailed callback:^(FPWCSApi2Call *call){
        [self changeCallStatus:call];
        [self toCallState];
    }];
    
    [call on:kFPWCSCallStatusRing callback:^(FPWCSApi2Call *call){
        [self changeCallStatus:call];
        [self toHangupState];
    }];
    
    [call on:kFPWCSCallStatusHold callback:^(FPWCSApi2Call *call){
        [self changeCallStatus:call];
        [self changeViewState:_holdButton enabled:YES];
    }];
    
    [call on:kFPWCSCallStatusEstablished callback:^(FPWCSApi2Call *call){
        [self changeCallStatus:call];
        _useLoudSpeaker.control.userInteractionEnabled = YES;
        [self toHangupState];
        [self changeViewState:_holdButton enabled:YES];
    }];
    
    [call on:kFPWCSCallStatusFinish callback:^(FPWCSApi2Call *call){
        [self changeCallStatus:call];
        _useLoudSpeaker.control.userInteractionEnabled = NO;
        [_useLoudSpeaker.control setOn: NO animated:YES];

        [self toCallState];
    }];
    
    [call call];
    return call;
}

//session and stream status handlers
- (void)onConnected:(FPWCSApi2Session *)session {
    [_connectButton setTitle:@"DISCONNECT" forState:UIControlStateNormal];
    [self changeViewState:_connectButton enabled:YES];

    [_connectTokenButton setTitle:@"DISCONNECT" forState:UIControlStateNormal];
    [self changeViewState:_connectTokenButton enabled:YES];

}

- (void)onDisconnected {
    [self toCallState];
    [_connectButton setTitle:@"CONNECT" forState:UIControlStateNormal];
    [self changeViewState:_connectButton enabled:YES];
    [_connectTokenButton setTitle:@"CONNECT WITH TOKEN" forState:UIControlStateNormal];
    [self changeViewState:_connectTokenButton enabled:_authToken.input.text.length > 0];

    [self changeViewState:_connectUrl enabled:YES];
    [self changeViewState:_sipLogin.input enabled:YES];
    [self changeViewState:_sipAuthName.input enabled:YES];
    [self changeViewState:_sipPassword.input enabled:YES];
    [self changeViewState:_sipDomain.input enabled:YES];
    [self changeViewState:_sipOutboundProxy.input enabled:YES];
    [self changeViewState:_sipRegRequired.control enabled:YES];
    [self changeViewState:_sipPort.input enabled:YES];
    [_callButton setTitle:@"CALL" forState:UIControlStateNormal];
    [self changeViewState:_callButton enabled:NO];
    [_holdButton setTitle:@"HOLD" forState:UIControlStateNormal];
    [self changeViewState:_holdButton enabled:NO];
    [self changeViewState:_dtmfButton enabled:NO];

}

- (void)toHangupState {
    [_callButton setTitle:@"HANGUP" forState:UIControlStateNormal];
    [self changeViewState:_callButton enabled:YES];
    [_holdButton setTitle:@"HOLD" forState:UIControlStateNormal];
    [self changeViewState:_holdButton enabled:YES];
    [self changeViewState:_dtmfButton enabled:YES];
}

- (void)toCallState {
    [_callButton setTitle:@"CALL" forState:UIControlStateNormal];
    [self changeViewState:_callButton enabled:YES];
    [_holdButton setTitle:@"HOLD" forState:UIControlStateNormal];
    [self changeViewState:_holdButton enabled:NO];
    [self changeViewState:_dtmfButton enabled:NO];
}

//user interface handlers

- (void)connectButton:(UIButton *)button {
    [self changeViewState:_connectButton enabled:NO];
    [self changeViewState:_connectTokenButton enabled:NO];
    if ([button.titleLabel.text isEqualToString:@"DISCONNECT"]) {
        if ([FPWCSApi2 getSessions].count) {
            FPWCSApi2Session *session = [FPWCSApi2 getSessions][0];
            NSLog(@"Disconnect session with server %@", [session getServerUrl]);
            [session disconnect];
        } else {
            NSLog(@"Nothing to disconnect");
            [self onDisconnected];
        }
    } else {
        //todo check url is not empty
        [self changeViewState:_connectUrl enabled:NO];
        [self changeViewState:_sipLogin.input enabled:NO];
        [self changeViewState:_sipAuthName.input enabled:NO];
        [self changeViewState:_sipPassword.input enabled:NO];
        [self changeViewState:_sipDomain.input enabled:NO];
        [self changeViewState:_sipOutboundProxy.input enabled:NO];
        [self changeViewState:_sipRegRequired.control enabled:NO];
        [self changeViewState:_sipPort.input enabled:NO];
        if (button == _connectButton) {
            [self connect];
        } else {
            [self connectWithToken];
        }
    }
}

- (void)callButton:(UIButton *)button {
    [self changeViewState:button enabled:NO];
    if ([button.titleLabel.text isEqualToString:@"HANGUP"]) {
        if ([FPWCSApi2 getSessions].count) {
            [call hangup];
        } else {
            [self toCallState];
        }
    } else {
        if ([FPWCSApi2 getSessions].count) {
            [self call];
        } else {
            [self toCallState];
        }
    }
}

- (void)holdButton:(UIButton *)button {
    [self changeViewState:button enabled:NO];
    if ([button.titleLabel.text isEqualToString:@"UNHOLD"]) {
        if (call) {
            [call unhold];
            [_holdButton setTitle:@"HOLD" forState:UIControlStateNormal];
        }
    } else {
        if (call) {
            [call hold];
            [_holdButton setTitle:@"UNHOLD" forState:UIControlStateNormal];
        }
    }
}

- (void)dtmfButton:(UIButton *)button {
    if (call) {
        [call sendDTMF:_dtmf.input.text type:kFPWCSCallDTMFRFC2833];
    }
}

- (void)useLoudSpeakerValueChanged:(id)sender {
    if (call) {
        [call setLoudspeakerStatus:_useLoudSpeaker.control.isOn withError:nil];
    }
}


//status handlers
- (void)changeConnectionStatus:(kFPWCSSessionStatus)status {
    _connectionStatus.text = [FPWCSApi2Model sessionStatusToString:status];
    switch (status) {
        case kFPWCSSessionStatusFailed:
            _connectionStatus.textColor = [UIColor redColor];
            break;
        case kFPWCSSessionStatusEstablished:
            _connectionStatus.textColor = [UIColor greenColor];
            break;
        case kFPWCSSessionStatusRegistered:
            _connectionStatus.textColor = [UIColor greenColor];
            break;
        default:
            _connectionStatus.textColor = [UIColor darkTextColor];
            break;
    }
}

- (void)changeCallStatus:(FPWCSApi2Call *)call {
    _callStatus.text = [FPWCSApi2Model callStatusToString:[call getStatus]];
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
    _sipLogin = [[WCSTextInputView alloc] init];
    _sipLogin.label.text = @"Sip Login";
    _sipAuthName = [[WCSTextInputView alloc] init];
    _sipAuthName.label.text = @"Sip Auth Name";
    _sipPassword = [[WCSTextInputView alloc] init];
    _sipPassword.label.text = @"Sip Password";
    _sipDomain = [[WCSTextInputView alloc] init];
    _sipDomain.label.text = @"Sip Domain";
    _sipOutboundProxy = [[WCSTextInputView alloc] init];
    _sipOutboundProxy.label.text = @"Sip Outbound Proxy";
    _sipPort = [[WCSTextInputView alloc] init];
    _sipPort.label.text = @"Sip Port";
    _sipRegRequired = [[WCSSwitchView alloc] init];
    _sipRegRequired.label.text = @"Sip Register Required";
    [_sipRegRequired.control setOn:YES];
    _connectButton = [WCSViewUtil createButton:@"CONNECT"];
    [_connectButton addTarget:self action:@selector(connectButton:) forControlEvents:UIControlEventTouchUpInside];

    _authToken = [[WCSTextInputView alloc] init];
    _authToken.label.text = @"Auth Token";

    _connectTokenButton = [WCSViewUtil createButton:@"CONNECT WITH TOKEN"];
    [_connectTokenButton addTarget:self action:@selector(connectButton:) forControlEvents:UIControlEventTouchUpInside];

    _connectionStatus = [WCSViewUtil createLabelView];

    _inviteParameters = [[WCSTextInputView alloc] init];
    _inviteParameters.label.text = @"Invite Parameters";

    _callee = [[WCSTextInputView alloc] init];
    _callee.label.text = @"Callee";
    _callStatus = [WCSViewUtil createLabelView];
    _callButton = [WCSViewUtil createButton:@"CALL"];
    [_callButton addTarget:self action:@selector(callButton:) forControlEvents:UIControlEventTouchUpInside];
    _holdButton = [WCSViewUtil createButton:@"HOLD"];
    [_holdButton addTarget:self action:@selector(holdButton:) forControlEvents:UIControlEventTouchUpInside];
    _useLoudSpeaker = [[WCSSwitchView alloc] initWithLabelText:@"Use Loud Speaker"];
    _useLoudSpeaker.control.userInteractionEnabled = NO;
    [_useLoudSpeaker.control addTarget:self action:@selector(useLoudSpeakerValueChanged:) forControlEvents:UIControlEventValueChanged];
    _dtmf = [[WCSTextInputView alloc] init];
    _dtmf.label.text = @"DTMF";
    _dtmfButton = [WCSViewUtil createButton:@"DTMF"];
    [_dtmfButton addTarget:self action:@selector(dtmfButton:) forControlEvents:UIControlEventTouchUpInside];
    
    [self.contentView addSubview:_connectUrl];
    [self.contentView addSubview:_sipLogin];
    [self.contentView addSubview:_sipAuthName];
    [self.contentView addSubview:_sipPassword];
    [self.contentView addSubview:_sipDomain];
    [self.contentView addSubview:_sipOutboundProxy];
    [self.contentView addSubview:_sipPort];
    [self.contentView addSubview:_sipRegRequired];
    [self.contentView addSubview:_connectButton];

    [self.contentView addSubview:_authToken];
    [self.contentView addSubview:_connectTokenButton];

    [self.contentView addSubview:_connectionStatus];
    [self.contentView addSubview:_inviteParameters];
    [self.contentView addSubview:_callee];
    [self.contentView addSubview:_callStatus];
    [self.contentView addSubview:_callButton];
    [self.contentView addSubview:_useLoudSpeaker];
    [self.contentView addSubview:_holdButton];
    [self.contentView addSubview:_dtmf];
    [self.contentView addSubview:_dtmfButton];
    
    [self.scrollView addSubview:_contentView];
    [self.view addSubview:_scrollView];
    
    //set default values
    _connectUrl.text = @"wss://demo.flashphoner.com:8443";
    _sipLogin.input.text = @"1000";
    _sipAuthName.input.text = @"1000";
    _sipPassword.input.text = @"1234";
    _sipDomain.input.text = @"192.168.0.1";
    _sipOutboundProxy.input.text = @"192.168.0.1";
    _sipPort.input.text = @"5060";
    _inviteParameters.input.text = @"{\"header\":\"value\"}";
    _callee.input.text = @"1001";
    _dtmf.input.text = @"1";

}

- (void)setupLayout {
    NSDictionary *views = @{
                            @"connectUrl": _connectUrl,
                            @"sipLogin": _sipLogin,
                            @"sipAuthName": _sipAuthName,
                            @"sipPassword":_sipPassword,
                            @"sipDomain":_sipDomain,
                            @"sipOutboundProxy":_sipOutboundProxy,
                            @"sipPort":_sipPort,
                            @"sipRegRequired":_sipRegRequired,
                            @"connectButton": _connectButton,
                            @"authToken": _authToken,
                            @"connectTokenButton": _connectTokenButton,
                            @"connectionStatus": _connectionStatus,
                            @"callee": _callee,
                            @"inviteParameters":_inviteParameters,
                            @"callStatus":_callStatus,
                            @"callButton":_callButton,
                            @"useLoudSpeaker": _useLoudSpeaker,
                            @"holdButton":_holdButton,
                            @"dtmf":_dtmf,
                            @"dtmfButton":_dtmfButton,
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
    
    //set height size
    setConstraint(_connectUrl, @"V:[connectUrl(inputFieldHeight)]", 0);
    setConstraint(_connectionStatus, @"V:[connectionStatus(statusHeight)]", 0);
    setConstraint(_connectButton, @"V:[connectButton(buttonHeight)]", 0);
    //set width related to super view
    setConstraint(_contentView, @"H:|-hSpacing-[connectUrl]-hSpacing-|", 0);
    setConstraint(_contentView, @"H:|-hSpacing-[sipLogin]-hSpacing-|",0);
    setConstraint(_contentView, @"H:|-hSpacing-[sipAuthName]-hSpacing-|",0);
    setConstraint(_contentView, @"H:|-hSpacing-[sipPassword]-hSpacing-|",0);
    setConstraint(_contentView, @"H:|-hSpacing-[sipDomain]-hSpacing-|",0);
    setConstraint(_contentView, @"H:|-hSpacing-[sipOutboundProxy]-hSpacing-|",0);
    setConstraint(_contentView, @"H:|-hSpacing-[sipPort]-hSpacing-|",0);
    setConstraint(_contentView, @"H:|-hSpacing-[sipRegRequired]-hSpacing-|",0);
    setConstraint(_contentView, @"H:|-hSpacing-[connectButton]-hSpacing-|",0);
    setConstraint(_contentView, @"H:|-hSpacing-[authToken]-hSpacing-|", 0);
    setConstraint(_contentView, @"H:|-hSpacing-[connectTokenButton]-hSpacing-|", 0);
    setConstraint(_contentView, @"H:|-hSpacing-[connectionStatus]-hSpacing-|", 0);
    setConstraint(_contentView, @"H:|-hSpacing-[inviteParameters]-hSpacing-|",0);
    setConstraint(_contentView, @"H:|-hSpacing-[callee]-hSpacing-|",0);
    setConstraint(_contentView, @"H:|-hSpacing-[callStatus]-hSpacing-|",0);
    setConstraint(_contentView, @"H:|-hSpacing-[callButton]-hSpacing-|",0);
    setConstraint(_contentView, @"H:|-hSpacing-[holdButton]-hSpacing-|",0);
    setConstraint(_contentView, @"H:|-hSpacing-[useLoudSpeaker]-hSpacing-|", 0);
    setConstraint(_contentView, @"H:|-hSpacing-[dtmf]-hSpacing-|",0);
    setConstraint(_contentView, @"H:|-hSpacing-[dtmfButton]-hSpacing-|",0);

    setConstraint(self.contentView, @"V:|-50-[connectUrl]-vSpacing-[sipLogin]-vSpacing-[sipAuthName]-vSpacing-[sipPassword]-vSpacing-[sipDomain]-vSpacing-[sipOutboundProxy]-vSpacing-[sipPort]-vSpacing-[sipRegRequired]-vSpacing-[connectButton]-vSpacing-[authToken]-vSpacing-[connectTokenButton]-vSpacing-[connectionStatus]-vSpacing-[inviteParameters]-vSpacing-[callee]-vSpacing-[callStatus]-vSpacing-[callButton]-vSpacing-[holdButton]-vSpacing-[useLoudSpeaker]-vSpacing-[dtmf]-vSpacing-[dtmfButton]-vSpacing-|", 0);
    
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
