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

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupViews];
    [self setupLayout];
}




- (void)startButton:(UIButton *)button {
    NSLog(@"Start button pressed");
}
- (void)localSettingsButton:(UIButton *)button {
    [_localControl show];
}
- (void)remoteSettingsButton:(UIButton *)button {
    [_remoteControl show];
}

- (void)onStarted {
    
}

//user interface views and layout
- (void)setupViews {
    _startButton = [WCSViewUtil createButton:@"Start"];
    [_startButton addTarget:self action:@selector(startButton:) forControlEvents:UIControlEventTouchUpInside];
    _localSettingsButton = [WCSViewUtil createButton:@"Local settings"];
    [_localSettingsButton addTarget:self action:@selector(localSettingsButton:) forControlEvents:UIControlEventTouchUpInside];
    _remoteSettingsButton = [WCSViewUtil createButton:@"Remote settings"];
    [_remoteSettingsButton addTarget:self action:@selector(remoteSettingsButton:) forControlEvents:UIControlEventTouchUpInside];
    _settingsButtonContainer = [[UIView alloc] init];
    _settingsButtonContainer.translatesAutoresizingMaskIntoConstraints = NO;
    _urlInput = [WCSViewUtil createTextField:self];
    _videoView = [[WCSDoubleVideoView alloc] init];
    _localControl = [[WCSLocalVideoControlView alloc] init];
    _remoteControl = [[WCSRemoteVideoControlView alloc] init];
    _contentView = [[UIView alloc] init];
    _contentView.translatesAutoresizingMaskIntoConstraints = NO;
    [_contentView addSubview:_startButton];
    [_settingsButtonContainer addSubview:_localSettingsButton];
    [_settingsButtonContainer addSubview:_remoteSettingsButton];
    [_contentView addSubview:_settingsButtonContainer];
    [_contentView addSubview:_urlInput];
    [_contentView addSubview:_videoView];
    [self.view addSubview:_contentView];
    [self.view addSubview:_localControl];
    [self.view addSubview:_remoteControl];
}

- (void)setupLayout {
    
    NSDictionary *views = @{
                            @"start": _startButton,
                            @"localSettings": _localSettingsButton,
                            @"remoteSettings": _remoteSettingsButton,
                            @"settings": _settingsButtonContainer,
                            @"urlInput": _urlInput,
                            @"videoView": _videoView,
                            @"content": _contentView,
                            @"localControl": _localControl,
                            @"remoteControl": _remoteControl
                            };
    NSDictionary *metrics = @{
                              @"height": @30,
                              @"vSpacing": @30,
                              @"hSpacing": @30
                              };

    void (^setConstraint)(UIView*, NSString*, NSLayoutFormatOptions) = ^(UIView *view, NSString *constraint, NSLayoutFormatOptions options) {
        [view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:constraint options:options metrics:metrics views:views]];
    };
    
    setConstraint(_startButton, @"V:[start(height)]", 0);
    setConstraint(_contentView, @"H:|[start]|", 0);
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
    setConstraint(_contentView, @"H:|[videoView]|", 0);
    
    setConstraint(_contentView, @"V:|-vSpacing-[videoView]-[settings]-vSpacing-[urlInput]-vSpacing-[start]-vSpacing-|", 0);
    
    setConstraint(self.view, @"H:|[content]|", 0);
    setConstraint(self.view, @"V:|[content]|", 0);
    setConstraint(self.view, @"V:|-vSpacing-[localControl]-vSpacing-|", 0);
    setConstraint(self.view, @"V:|-vSpacing-[remoteControl]-vSpacing-|", 0);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}
@end
