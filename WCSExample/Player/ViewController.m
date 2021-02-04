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
#import <Metal/Metal.h>

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
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
    options.appKey = @"defaultApp";
    NSError *error;
    FPWCSApi2Session *session = [FPWCSApi2 createSession:options error:&error];
    if (!session) {
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
    }];
    
    [session on:kFPWCSSessionStatusFailed callback:^(FPWCSApi2Session *rSession){
        [self changeConnectionStatus:[rSession getStatus]];
        [self onDisconnected];
    }];
    [session connect];
    return session;
}

- (FPWCSApi2Stream *)playStream {
    FPWCSApi2Session *session = [FPWCSApi2 getSessions][0];
    FPWCSApi2StreamOptions *options = [[FPWCSApi2StreamOptions alloc] init];
    options.name = _remoteStreamName.text;
    options.display = _remoteDisplay;
    NSError *error;
    FPWCSApi2Stream *stream = [session createStream:options error:nil];
    if (!stream) {
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
        return nil;
    }
    [stream on:kFPWCSStreamStatusPlaying callback:^(FPWCSApi2Stream *rStream){
        [self changeStreamStatus:rStream];
        [self onPlaying:rStream];
    }];
    
    [stream on:kFPWCSStreamStatusNotEnoughtBandwidth callback:^(FPWCSApi2Stream *rStream){
        NSLog(@"Not enough bandwidth stream %@, consider using lower video resolution or bitrate. Bandwidth %ld bitrate %ld", [rStream getName], [stream getNetworkBandwidth] / 1000, [stream getRemoteBitrate] / 1000);
        [self changeStreamStatus:rStream];
    }];
    
    
    [stream on:kFPWCSStreamStatusStopped callback:^(FPWCSApi2Stream *rStream){
        [self changeStreamStatus:rStream];
        [self onDisconnected];
    }];
    
    [stream on:kFPWCSStreamStatusFailed callback:^(FPWCSApi2Stream *rStream){
        [self changeStreamStatus:rStream];
        [self onDisconnected];
    }];
    if(![stream play:&error]) {
        UIAlertController * alert = [UIAlertController
                                     alertControllerWithTitle:@"Failed to play"
                                     message:error.localizedDescription
                                     preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction* okButton = [UIAlertAction
                                   actionWithTitle:@"Ok"
                                   style:UIAlertActionStyleDefault
                                   handler:^(UIAlertAction * action) {
                                       
                                   }];
        
        [alert addAction:okButton];
        [self presentViewController:alert animated:YES completion:nil];
    }
    return stream;
}

//session and stream status handlers
- (void)onConnected:(FPWCSApi2Session *)session {
    [self changeViewState:_remoteStreamName enabled:NO];
    [self playStream];
}

- (void)onDisconnected {
    [self changeViewState:_connectUrl enabled:YES];
    [self onStopped];
}

- (void)onPlaying:(FPWCSApi2Stream *)stream {
    [_startButton setTitle:@"STOP" forState:UIControlStateNormal];
    [self changeViewState:_startButton enabled:YES];
}

- (void)onStopped {
    [_startButton setTitle:@"START" forState:UIControlStateNormal];
    [self changeViewState:_startButton enabled:YES];
    [self changeViewState:_remoteStreamName enabled:YES];
    [_remoteDisplay renderFrame:nil];
}

//user interface handlers

- (void)startButton:(UIButton *)button {
    [self changeViewState:button enabled:NO];
    if ([button.titleLabel.text isEqualToString:@"STOP"]) {
        if ([FPWCSApi2 getSessions].count) {
            FPWCSApi2Session *session = [FPWCSApi2 getSessions][0];
            NSLog(@"Disconnect session with server %@", [session getServerUrl]);
            [session disconnect];
        } else {
            NSLog(@"Nothing to disconnect");
            [self onDisconnected];
        }
    } else {
        [self changeViewState:_connectUrl enabled:NO];
        [self connect];
    }
}

- (void)fullscreenButton:(UITapGestureRecognizer *)recognizer {
    [_remoteDisplay removeConstraints: [_remoteDisplay constraints]];
        
    if (_fullscreen) {
        [_remoteDisplay removeFromSuperview];
        [_videoContainer addSubview:_remoteDisplay];
        
        NSLayoutConstraint *constraint =[NSLayoutConstraint constraintWithItem:_remoteDisplay attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:_remoteDisplay attribute:NSLayoutAttributeHeight multiplier:640.0/480.0 constant:0];
        [_remoteDisplay addConstraint:constraint];

        constraint =[NSLayoutConstraint constraintWithItem:_remoteDisplay attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationLessThanOrEqual toItem:_videoContainer attribute:NSLayoutAttributeWidth multiplier:1.0 constant:0];
        [_videoContainer addConstraint:constraint];

        [_videoContainer addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[remoteDisplay]|" options:NSLayoutFormatAlignAllTop metrics:@{} views:@{@"remoteDisplay": _remoteDisplay}]];

        [_videoContainer addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[remoteDisplay]|" options:0 metrics:@{} views:@{@"remoteDisplay": _remoteDisplay}]];
    } else {
        [_remoteDisplay.widthAnchor constraintEqualToConstant: [[UIScreen mainScreen] bounds].size.width].active = YES;
        [_remoteDisplay.heightAnchor constraintEqualToConstant:[[UIScreen mainScreen] bounds].size.height].active = YES;
        [_remoteDisplay removeFromSuperview];
        [_scrollView addSubview:_remoteDisplay];
    }
    _fullscreen = !_fullscreen;
}

//status handlers
- (void)changeConnectionStatus:(kFPWCSSessionStatus)status {
    _status.text = [FPWCSApi2Model sessionStatusToString:status];
    switch (status) {
        case kFPWCSSessionStatusFailed:
            _status.textColor = [UIColor redColor];
            break;
        case kFPWCSSessionStatusEstablished:
            _status.textColor = [UIColor greenColor];
            break;
        default:
            _status.textColor = [UIColor darkTextColor];
            break;
    }
}

- (void)changeStreamStatus:(FPWCSApi2Stream *)stream {
    _status.text = [FPWCSApi2Model streamStatusToString:[stream getStatus]];
    switch ([stream getStatus]) {
        case kFPWCSStreamStatusFailed:
            _status.textColor = [UIColor redColor];
            break;
        case kFPWCSStreamStatusPlaying:
        case kFPWCSStreamStatusPublishing:
            _status.textColor = [UIColor greenColor];
            break;
        default:
            _status.textColor = [UIColor darkTextColor];
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
    
    _videoContainer = [[UIView alloc] init];
    _videoContainer.translatesAutoresizingMaskIntoConstraints = NO;
    
    id<MTLDevice> remoteDevice;
#ifdef __aarch64__
    remoteDevice = MTLCreateSystemDefaultDevice();
    if (remoteDevice) {
        RTCMTLVideoView *remoteView = [[RTCMTLVideoView alloc] init];
        remoteView.delegate = self;
        remoteView.videoContentMode = UIViewContentModeScaleAspectFit;
        _remoteDisplay = remoteView;
        _remoteDisplay.backgroundColor = [UIColor blackColor];
        UITapGestureRecognizer *singleFingerTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(fullscreenButton:)];
        singleFingerTap.numberOfTapsRequired = 2;
        [_remoteDisplay addGestureRecognizer:singleFingerTap];
    }
#endif
    if (!_remoteDisplay) {
        RTCEAGLVideoView *remoteView = [[RTCEAGLVideoView alloc] init];
        remoteView.delegate = self;
        _remoteDisplay = remoteView;
    }
    _remoteDisplay.translatesAutoresizingMaskIntoConstraints = NO;

    _connectUrl = [WCSViewUtil createTextField:self];
    
    _playStreamLabel = [WCSViewUtil createInfoLabel:@"Play Stream"];
    _remoteStreamName = [WCSViewUtil createTextField:self];
    _status = [WCSViewUtil createLabelView];
    _startButton = [WCSViewUtil createButton:@"PLAY"];
    [_startButton addTarget:self action:@selector(startButton:) forControlEvents:UIControlEventTouchUpInside];

    _fullscreenButton = [WCSViewUtil createButton:@"Full screen"];
    [_fullscreenButton addTarget:self action:@selector(fullscreenButton:) forControlEvents:UIControlEventTouchUpInside];

    [self.videoContainer addSubview:_remoteDisplay];
    
    [self.contentView addSubview:_connectUrl];
    [self.contentView addSubview:_playStreamLabel];
    [self.contentView addSubview:_remoteStreamName];
    [self.contentView addSubview:_status];
    [self.contentView addSubview:_startButton];
    [self.contentView addSubview:_fullscreenButton];
    
    [self.contentView addSubview:_videoContainer];
    
    [self.scrollView addSubview:_contentView];
    [self.view addSubview:_scrollView];
    
    //set default values
    _connectUrl.text = @"wss://demo.flashphoner.com:8443/";
    _remoteStreamName.text = @"streamName";
}


- (void)setupLayout {
    NSDictionary *views = @{
                            @"connectUrl": _connectUrl,
                            @"playStreamLabel": _playStreamLabel,
                            @"remoteStreamName": _remoteStreamName,
                            @"status": _status,
                            @"startButton": _startButton,
                            @"fullscreenButton": _fullscreenButton,
                            @"remoteDisplay": _remoteDisplay,
                            @"videoContainer": _videoContainer,
                            @"contentView": _contentView,
                            @"scrollView": _scrollView
                            };
    
    NSDictionary *metrics = @{
                              @"buttonHeight": @30,
                              @"statusHeight": @30,
                              @"labelHeight": @20,
                              @"inputFieldHeight": @30,
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
    
    _remoteDisplayConstraints = [[NSMutableArray alloc] init];
    
    //set height size
    setConstraint(_connectUrl, @"V:[connectUrl(inputFieldHeight)]", 0);
    setConstraint(_playStreamLabel, @"V:[playStreamLabel(labelHeight)]", 0);
    setConstraint(_remoteStreamName, @"V:[remoteStreamName(inputFieldHeight)]", 0);
    setConstraint(_status, @"V:[status(statusHeight)]", 0);
    setConstraint(_startButton, @"V:[startButton(buttonHeight)]", 0);
    setConstraint(_fullscreenButton, @"V:[fullscreenButton(buttonHeight)]", 0);
    
    //set width related to super view
    setConstraint(_contentView, @"H:|-hSpacing-[connectUrl]-hSpacing-|", 0);
    setConstraint(_contentView, @"H:|-hSpacing-[playStreamLabel]-hSpacing-|", 0);
    setConstraint(_contentView, @"H:|-hSpacing-[remoteStreamName]-hSpacing-|", 0);
    setConstraint(_contentView, @"H:|-hSpacing-[status]-hSpacing-|", 0);
    setConstraint(_contentView, @"H:|-hSpacing-[startButton]-hSpacing-|", 0);
    setConstraint(_contentView, @"H:|-hSpacing-[fullscreenButton]-hSpacing-|", 0);
    setConstraint(_contentView, @"H:|-hSpacing-[videoContainer]-hSpacing-|", 0);
    
    //remote display max width and height
    setConstraintWithItem(_videoContainer, _remoteDisplay, _videoContainer, NSLayoutAttributeWidth, NSLayoutRelationLessThanOrEqual, NSLayoutAttributeWidth, 1.0, 0);
    
    //remote display aspect ratio
    NSLayoutConstraint *remoteARConstraint = setConstraintWithItem(_remoteDisplay, _remoteDisplay, _remoteDisplay, NSLayoutAttributeWidth, NSLayoutRelationEqual, NSLayoutAttributeHeight, 640.0/480.0, 0);
    [_remoteDisplayConstraints addObject:remoteARConstraint];
    
    //position video views inside video container
    setConstraint(_videoContainer, @"H:|[remoteDisplay]|", NSLayoutFormatAlignAllTop);
    setConstraint(_videoContainer, @"V:|[remoteDisplay]|", 0);
    
    setConstraint(self.contentView, @"V:|-50-[connectUrl]-vSpacing-[playStreamLabel]-vSpacing-[remoteStreamName]-vSpacing-[status]-vSpacing-[startButton]-vSpacing-[fullscreenButton]-vSpacing-[videoContainer]-vSpacing-|", 0);
    
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

#pragma mark - RTCEAGLVideoViewDelegate

- (void)videoView:(RTCEAGLVideoView*)videoView didChangeVideoSize:(CGSize)size {
    
    NSLog(@"Size of remote video %fx%f", size.width, size.height);
    [_remoteDisplay removeConstraints:_remoteDisplayConstraints];
    [_remoteDisplayConstraints removeAllObjects];
    NSLayoutConstraint *constraint =[NSLayoutConstraint
                                     constraintWithItem:_remoteDisplay
                                     attribute:NSLayoutAttributeWidth
                                     relatedBy:NSLayoutRelationEqual
                                     toItem:_remoteDisplay
                                     attribute:NSLayoutAttributeHeight
                                     multiplier:size.width/size.height
                                     constant:0.0f];
    [_remoteDisplayConstraints addObject:constraint];
    [_remoteDisplay addConstraints:_remoteDisplayConstraints];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

@end
