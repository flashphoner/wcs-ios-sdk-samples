//
//  ViewController.m
//  WCSApiExample
//
//  Created by user on 24/11/2015.
//  Copyright © 2015 user. All rights reserved.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <FPWCSApi2/FPWCSApi2.h>
#import "WCSUtil.h"

@interface ViewController ()

@end

@implementation ViewController {
    FPWCSApi2Session *_session;
    FPWCSApi2Stream *_localStream;
    FPWCSApi2Stream *_remoteStream;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupViews];
    [self setupLayout];
}


- (void)start {
    if (!_session || [_session getStatus] != kFPWCSSessionStatusEstablished || ![[_session getServerUrl] isEqualToString:_urlInput.text]) {
        if (_session && ![[_session getServerUrl] isEqualToString:_urlInput.text]) {
            [_session on:kFPWCSSessionStatusDisconnected callback:^(FPWCSApi2Session *session){}];
            [_session on:kFPWCSSessionStatusFailed callback:^(FPWCSApi2Session *session){}];
            [_session disconnect];
        }
        FPWCSApi2SessionOptions *options = [[FPWCSApi2SessionOptions alloc] init];
        options.urlServer = _urlInput.text;
        options.appKey = @"defaultApp";
        NSError *error;
        _session = [FPWCSApi2 createSession:options error:&error];
        if (!_session) {
            UIAlertController * alert = [UIAlertController
                                         alertControllerWithTitle:@"Failed to connect"
                                         message:error.localizedDescription
                                         preferredStyle:UIAlertControllerStyleAlert];
            
            UIAlertAction* okButton = [UIAlertAction
                                       actionWithTitle:@"Ok"
                                       style:UIAlertActionStyleDefault
                                       handler:^(UIAlertAction * action) {
                                           [self onStopped];
                                       }];
            
            [alert addAction:okButton];
            [self presentViewController:alert animated:YES completion:nil];
            return;
        }
        
        [_session on:kFPWCSSessionStatusEstablished callback:^(FPWCSApi2Session *session){
            [self changeConnectionStatus:[session getStatus]];
            [self startStreaming];
        }];
        
        [_session on:kFPWCSSessionStatusDisconnected callback:^(FPWCSApi2Session *session){
            [self changeConnectionStatus:[session getStatus]];
            [self onStopped];
        }];
        
        [_session on:kFPWCSSessionStatusFailed callback:^(FPWCSApi2Session *session){
            [self changeConnectionStatus:[session getStatus]];
            [self onStopped];
        }];
        [_session connect];
    } else {
        [self startStreaming];
    }
}

- (void)startStreaming {
    FPWCSApi2StreamOptions *options = [[FPWCSApi2StreamOptions alloc] init];
    options.name = [self getStreamName];
    options.display = _videoView.local;
    options.constraints = [_localControl toMediaConstraints];
    NSError *error;
    _localStream = [_session createStream:options error:&error];
    if (!_localStream) {
        UIAlertController * alert = [UIAlertController
                                     alertControllerWithTitle:@"Failed to publish"
                                     message:error.localizedDescription
                                     preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction* okButton = [UIAlertAction
                                   actionWithTitle:@"Ok"
                                   style:UIAlertActionStyleDefault
                                   handler:^(UIAlertAction * action) {
                                       [self onStopped];
                                   }];
        
        [alert addAction:okButton];
        [self presentViewController:alert animated:YES completion:nil];
        return;
    }
    //initial mute
    if (_localControl.muteAudio.control.isOn) {
        [_localStream muteAudio];
    }
    if (_localControl.muteVideo.control.isOn) {
        [_localStream muteVideo];
    }
    
    if (_lockCameraOrientation.control.isOn) {
        [_localStream lockCameraOrientation];
    }
    [_localStream on:kFPWCSStreamStatusPublishing callback:^(FPWCSApi2Stream *stream){
        [self changeStreamStatus:stream];
        [self startPlaying];
    }];
    
    [_localStream on:kFPWCSStreamStatusUnpublished callback:^(FPWCSApi2Stream *stream){
        [self changeStreamStatus:stream];
        [self onStopped];
    }];
    
    [_localStream on:kFPWCSStreamStatusFailed callback:^(FPWCSApi2Stream *stream){
        [self changeStreamStatus:stream];
        [self onStopped];
    }];
    if(![_localStream publish:&error]) {
        UIAlertController * alert = [UIAlertController
                                     alertControllerWithTitle:@"Failed to publish"
                                     message:error.localizedDescription
                                     preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction* okButton = [UIAlertAction
                                   actionWithTitle:@"Ok"
                                   style:UIAlertActionStyleDefault
                                   handler:^(UIAlertAction * action) {
                                       [self onStopped];
                                   }];
        
        [alert addAction:okButton];
        [self presentViewController:alert animated:YES completion:nil];
    }
}

- (void)startPlaying {
    FPWCSApi2StreamOptions *options = [[FPWCSApi2StreamOptions alloc] init];
    options.name = [_localStream getName];
    options.display = _videoView.remote;
    options.constraints = [_remoteControl toMediaConstraints];
    NSError *error;
    _remoteStream = [_session createStream:options error:&error];
    if (!_remoteStream) {
        UIAlertController * alert = [UIAlertController
                                     alertControllerWithTitle:@"Failed to play"
                                     message:error.localizedDescription
                                     preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction* okButton = [UIAlertAction
                                   actionWithTitle:@"Ok"
                                   style:UIAlertActionStyleDefault
                                   handler:^(UIAlertAction * action) {
                                       [self onStopped];
                                   }];
        
        [alert addAction:okButton];
        [self presentViewController:alert animated:YES completion:nil];
        return;
    }
    [_remoteStream on:kFPWCSStreamStatusPlaying callback:^(FPWCSApi2Stream *stream){
        [self changeStreamStatus:stream];
        [self onStarted];
    }];
    
    [_remoteStream on:kFPWCSStreamStatusNotEnoughtBandwidth callback:^(FPWCSApi2Stream *rStream){
        NSLog(@"Not enough bandwidth stream %@, consider using lower video resolution or bitrate. Bandwidth %ld bitrate %ld", [rStream getName], [rStream getNetworkBandwidth] / 1000, [rStream getRemoteBitrate] / 1000);
        [self changeStreamStatus:rStream];
    }];
    
    [_remoteStream on:kFPWCSStreamStatusStopped callback:^(FPWCSApi2Stream *rStream){
        [self changeStreamStatus:rStream];
        [_localStream stop:nil];
    }];
    [_remoteStream on:kFPWCSStreamStatusFailed callback:^(FPWCSApi2Stream *rStream){
        [self changeStreamStatus:rStream];
        if (_localStream && [_localStream getStatus] == kFPWCSStreamStatusPublishing) {
            [_localStream stop:nil];
        }
    }];
    if(![_remoteStream play:&error]) {
        UIAlertController * alert = [UIAlertController
                                     alertControllerWithTitle:@"Failed to play"
                                     message:error.localizedDescription
                                     preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction* okButton = [UIAlertAction
                                   actionWithTitle:@"Ok"
                                   style:UIAlertActionStyleDefault
                                   handler:^(UIAlertAction * action) {
                                       if (_localStream && [_localStream getStatus] == kFPWCSStreamStatusPublishing) {
                                           [_localStream stop:nil];
                                       }
                                   }];
        
        [alert addAction:okButton];
        [self presentViewController:alert animated:YES completion:nil];
    }

}

- (void)onStarted {
    [_startButton setTitle:@"Stop" forState:UIControlStateNormal];
    _startButton.userInteractionEnabled = YES;
    _startButton.alpha = 1;
}

- (void)onStopped {
    [_startButton setTitle:@"Start" forState:UIControlStateNormal];
    _startButton.userInteractionEnabled = YES;
    _startButton.alpha = 1;
    _urlInput.userInteractionEnabled = YES;
    if (_localStream) {
        [FPWCSApi2 releaseLocalMedia:_videoView.local];
    }
}

- (void)startButton:(UIButton *)button {
    button.userInteractionEnabled = NO;
    button.alpha = 0.5;
    _urlInput.userInteractionEnabled = NO;
    if ([button.titleLabel.text isEqualToString:@"Stop"]) {
        if (_remoteStream) {
            NSError *error;
            [_remoteStream stop:&error];
        } else {
            NSLog(@"No remote stream, failed to stop");
        }
    } else {
        //start
        [self start];
    }
}
- (void)localSettingsButton:(UIButton *)button {
    [_localControl show];
}
- (void)remoteSettingsButton:(UIButton *)button {
    [_remoteControl show];
}



- (void)lockCameraOrientationValueChanged:(id)sender {
    if (_localStream) {
        if  (_lockCameraOrientation.control.isOn) {
            [_localStream lockCameraOrientation];
        } else {
            [_localStream unlockCameraOrientation];
        }
    }
}

- (void)controlValueChanged:(id)sender {
    if (sender == _localControl.muteAudio.control) {
        if (_localStream) {
            if (_localControl.muteAudio.control.isOn) {
                [_localStream muteAudio];
            } else {
                [_localStream unmuteAudio];
            }
        }
    } else if (sender == _localControl.muteVideo.control) {
        if (_localStream) {
            if (_localControl.muteVideo.control.isOn) {
                [_localStream muteVideo];
            } else {
                [_localStream unmuteVideo];
            }
        }
    }
}

- (void)changeConnectionStatus:(kFPWCSSessionStatus)status {
    _connectStatus.text = [FPWCSApi2Model sessionStatusToString:status];
    switch (status) {
        case kFPWCSSessionStatusFailed:
            _connectStatus.textColor = [UIColor redColor];
            break;
        case kFPWCSSessionStatusEstablished:
            _connectStatus.textColor = [UIColor greenColor];
            break;
        default:
            _connectStatus.textColor = [UIColor darkTextColor];
            break;
    }
}

- (void)changeStreamStatus:(FPWCSApi2Stream *)stream {
    _connectStatus.text = [FPWCSApi2Model streamStatusToString:[stream getStatus]];
    switch ([stream getStatus]) {
        case kFPWCSStreamStatusFailed:
            _connectStatus.textColor = [UIColor redColor];
            break;
        case kFPWCSStreamStatusPlaying:
        case kFPWCSStreamStatusPublishing:
            _connectStatus.textColor = [UIColor greenColor];
            break;
        default:
            _connectStatus.textColor = [UIColor darkTextColor];
            break;
    }
}

//user interface views and layout
- (void)setupViews {
    _scrollView = [[UIScrollView alloc] init];
    _scrollView.translatesAutoresizingMaskIntoConstraints = NO;
    _scrollView.scrollEnabled = YES;
    _startButton = [WCSViewUtil createButton:@"Start"];
    [_startButton addTarget:self action:@selector(startButton:) forControlEvents:UIControlEventTouchUpInside];
    _lockCameraOrientation = [[WCSSwitchView alloc] initWithLabelText:@"Lock Camera Orientation"];
    [_lockCameraOrientation.control addTarget:self action:@selector(lockCameraOrientationValueChanged:) forControlEvents:UIControlEventValueChanged];
    _localSettingsButton = [WCSViewUtil createButton:@"Local settings"];
    [_localSettingsButton addTarget:self action:@selector(localSettingsButton:) forControlEvents:UIControlEventTouchUpInside];
    _remoteSettingsButton = [WCSViewUtil createButton:@"Remote settings"];
    [_remoteSettingsButton addTarget:self action:@selector(remoteSettingsButton:) forControlEvents:UIControlEventTouchUpInside];
    _settingsButtonContainer = [[UIView alloc] init];
    _settingsButtonContainer.translatesAutoresizingMaskIntoConstraints = NO;
    _urlInput = [WCSViewUtil createTextField:self];
    _urlInput.text = @"wss://wcs5-eu.flashphoner.com:8443";
    _connectStatus = [WCSViewUtil createLabelView];
    _videoView = [[WCSDoubleVideoView alloc] init];
    _localControl = [[WCSLocalVideoControlView alloc] init];
    [_localControl.muteAudio.control addTarget:self action:@selector(controlValueChanged:) forControlEvents:UIControlEventValueChanged];
    [_localControl.muteVideo.control addTarget:self action:@selector(controlValueChanged:) forControlEvents:UIControlEventValueChanged];
    _remoteControl = [[WCSRemoteVideoControlView alloc] init];
    _contentView = [[UIView alloc] init];
    _contentView.translatesAutoresizingMaskIntoConstraints = NO;
    [_contentView addSubview:_startButton];
    [_contentView addSubview:_lockCameraOrientation];
    [_settingsButtonContainer addSubview:_localSettingsButton];
    [_settingsButtonContainer addSubview:_remoteSettingsButton];
    [_contentView addSubview:_settingsButtonContainer];
    [_contentView addSubview:_urlInput];
    [_contentView addSubview:_connectStatus];
    [_contentView addSubview:_videoView];
    [_scrollView addSubview:_contentView];
    [self.view addSubview:_scrollView];
    [self.view addSubview:_localControl];
    [self.view addSubview:_remoteControl];
}

- (void)setupLayout {
    
    NSDictionary *views = @{
                            @"start": _startButton,
                            @"lockOrientation": _lockCameraOrientation,
                            @"localSettings": _localSettingsButton,
                            @"remoteSettings": _remoteSettingsButton,
                            @"settings": _settingsButtonContainer,
                            @"urlInput": _urlInput,
                            @"connectStatus": _connectStatus,
                            @"videoView": _videoView,
                            @"content": _contentView,
                            @"localControl": _localControl,
                            @"remoteControl": _remoteControl,
                            @"scroll": _scrollView
                            };
    NSDictionary *metrics = @{
                              @"height": @30,
                              @"vSpacing": @30,
                              @"hSpacing": @10
                              };

    void (^setConstraint)(UIView*, NSString*, NSLayoutFormatOptions) = ^(UIView *view, NSString *constraint, NSLayoutFormatOptions options) {
        [view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:constraint options:options metrics:metrics views:views]];
    };
    
    setConstraint(_startButton, @"V:[start(height)]", 0);
    setConstraint(_lockCameraOrientation, @"V:[lockOrientation(height)]", 0);
    setConstraint(_contentView, @"H:|[start]|", 0);
    setConstraint(_contentView, @"H:|[lockOrientation]|", 0);
    setConstraint(_localSettingsButton, @"V:[localSettings(height)]", 0);
    setConstraint(_remoteSettingsButton, @"V:[remoteSettings(height)]", 0);
    [_settingsButtonContainer addConstraint:[NSLayoutConstraint
                                             constraintWithItem:_localSettingsButton
                                             attribute:NSLayoutAttributeLeft
                                             relatedBy:NSLayoutRelationEqual
                                             toItem:_settingsButtonContainer
                                             attribute:NSLayoutAttributeLeft
                                             multiplier:1
                                             constant:0.0f]];
    [_settingsButtonContainer addConstraint:[NSLayoutConstraint
                                     constraintWithItem:_localSettingsButton
                                     attribute:NSLayoutAttributeWidth
                                     relatedBy:NSLayoutRelationEqual
                                     toItem:_settingsButtonContainer
                                     attribute:NSLayoutAttributeWidth
                                     multiplier:0.48
                                     constant:0.0f]];
    [_settingsButtonContainer addConstraint:[NSLayoutConstraint
                                             constraintWithItem:_remoteSettingsButton
                                             attribute:NSLayoutAttributeRight
                                             relatedBy:NSLayoutRelationEqual
                                             toItem:_settingsButtonContainer
                                             attribute:NSLayoutAttributeRight
                                             multiplier:1
                                             constant:0.0f]];
    [_settingsButtonContainer addConstraint:[NSLayoutConstraint
                                             constraintWithItem:_remoteSettingsButton
                                             attribute:NSLayoutAttributeWidth
                                             relatedBy:NSLayoutRelationEqual
                                             toItem:_settingsButtonContainer
                                             attribute:NSLayoutAttributeWidth
                                             multiplier:0.48
                                             constant:0.0f]];
    setConstraint(_settingsButtonContainer, @"V:|[localSettings]|", 0);
    setConstraint(_settingsButtonContainer, @"V:|[remoteSettings]|", 0);
    setConstraint(_settingsButtonContainer, @"V:[settings(height)]", 0);
    setConstraint(_contentView, @"H:|[settings]|", 0);
    setConstraint(_urlInput, @"V:[urlInput(height)]", 0);
    setConstraint(_contentView, @"H:|[urlInput]|", 0);
    setConstraint(_contentView, @"H:|[connectStatus]|", 0);
    setConstraint(_contentView, @"H:|[videoView]|", 0);
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:_videoView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationGreaterThanOrEqual toItem:self.view attribute:NSLayoutAttributeHeight multiplier:0.5 constant:0]];
    
    setConstraint(_contentView, @"V:|[videoView]-[settings]-vSpacing-[lockOrientation]-vSpacing-[urlInput]-vSpacing-[connectStatus]-vSpacing-[start]|", 0);
    setConstraint(_scrollView, @"V:|[content]|", 0);
    setConstraint(self.view, @"H:|[scroll]|", 0);
    setConstraint(self.view, @"H:|-hSpacing-[content]-hSpacing-|", 0);
    
    setConstraint(self.view, @"V:|-vSpacing-[scroll]|", 0);
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:_contentView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeWidth multiplier:1 constant:-20]];
    setConstraint(self.view, @"V:|-vSpacing-[localControl]|", 0);
    setConstraint(self.view, @"V:|-vSpacing-[remoteControl]|", 0);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    [[WCSKeyboardTracker sharedInstance] update:textField];
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    [[WCSKeyboardTracker sharedInstance] update];
}


- (NSString *)getStreamName {
    NSArray *split = [_urlInput.text componentsSeparatedByString:@"/"];
    if (split.count > 3 && ((NSString *)(split[3])).length > 0) {
        return split[3];
    }
    return [[[NSUUID UUID] UUIDString] substringToIndex:8];
}

@end
