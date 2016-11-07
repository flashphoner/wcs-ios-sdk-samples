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
    FPWCSApi2Session *session = [FPWCSApi2 createSession:options error:nil];
    
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

- (FPWCSApi2Stream *)publishStream {
    FPWCSApi2Session *session = [FPWCSApi2 getSessions][0];
    FPWCSApi2StreamOptions *options = [[FPWCSApi2StreamOptions alloc] init];
    options.name = _localStreamName.text;
    options.display = _localDisplay;
    FPWCSApi2Stream *stream = [session createStream:options];
    [stream on:kFPWCSStreamStatusPublishing callback:^(FPWCSApi2Stream *rStream){
        [self changeStreamStatus:rStream];
        [self onPublishing:rStream];
    }];

    [stream on:kFPWCSStreamStatusUnpublished callback:^(FPWCSApi2Stream *rStream){
        [self changeStreamStatus:rStream];
        [self onUnpublished];
    }];
    
    [stream on:kFPWCSStreamStatusFailed callback:^(FPWCSApi2Stream *rStream){
        [self changeStreamStatus:rStream];
        [self onUnpublished];
    }];
    [stream publish];
    return stream;
}

- (FPWCSApi2Stream *)playStream {
    FPWCSApi2Session *session = [FPWCSApi2 getSessions][0];
    FPWCSApi2StreamOptions *options = [[FPWCSApi2StreamOptions alloc] init];
    options.name = _remoteStreamName.text;
    options.display = _remoteDisplay;
    FPWCSApi2Stream *stream = [session createStream:options];
    [stream on:kFPWCSStreamStatusPlaying callback:^(FPWCSApi2Stream *rStream){
        [self changeStreamStatus:rStream];
        [self onPlaying:rStream];
    }];
    
    [stream on:kFPWCSStreamStatusStopped callback:^(FPWCSApi2Stream *rStream){
        [self changeStreamStatus:rStream];
        [self onStopped];
    }];
    [stream on:kFPWCSStreamStatusFailed callback:^(FPWCSApi2Stream *rStream){
        [self changeStreamStatus:rStream];
        [self onStopped];
    }];
    [stream play];
    return stream;
}

//session and stream status handlers
- (void)onConnected:(FPWCSApi2Session *)session {
    [_connectButton setTitle:@"DISCONNECT" forState:UIControlStateNormal];
    [self changeViewState:_connectButton enabled:YES];
    [self onUnpublished];
    [self onStopped];
}

- (void)onDisconnected {
    [_connectButton setTitle:@"CONNECT" forState:UIControlStateNormal];
    [self changeViewState:_connectButton enabled:YES];
    [self changeViewState:_connectUrl enabled:YES];
    [self onUnpublished];
    [self onStopped];
}

- (void)onPublishing:(FPWCSApi2Stream *)stream {
    [_publishButton setTitle:@"STOP" forState:UIControlStateNormal];
    [self changeViewState:_publishButton enabled:YES];
}

- (void)onUnpublished {
    [_publishButton setTitle:@"PUBLISH" forState:UIControlStateNormal];
    if ([FPWCSApi2 getSessions].count && [[FPWCSApi2 getSessions][0] getStatus] == kFPWCSSessionStatusEstablished) {
        [self changeViewState:_publishButton enabled:YES];
        [self changeViewState:_localStreamName enabled:YES];
    } else {
        [self changeViewState:_publishButton enabled:NO];
        [self changeViewState:_localStreamName enabled:NO];
    }
    [FPWCSApi2 releaseLocalMedia:_localDisplay];
    [_localDisplay renderFrame:nil];
}

- (void)onPlaying:(FPWCSApi2Stream *)stream {
    [_playButton setTitle:@"STOP" forState:UIControlStateNormal];
    [self changeViewState:_playButton enabled:YES];
}

- (void)onStopped {
    [_playButton setTitle:@"PLAY" forState:UIControlStateNormal];
    if ([FPWCSApi2 getSessions].count && [[FPWCSApi2 getSessions][0] getStatus] == kFPWCSSessionStatusEstablished) {
        [self changeViewState:_playButton enabled:YES];
        [self changeViewState:_remoteStreamName enabled:YES];
    } else {
        [self changeViewState:_playButton enabled:NO];
        [self changeViewState:_remoteStreamName enabled:NO];
    }
    [_remoteDisplay renderFrame:nil];
}

//user interface handlers

- (void)connectButton:(UIButton *)button {
    [self changeViewState:button enabled:NO];
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
        [self connect];
    }
}

- (void)publishButton:(UIButton *)button {
    [self changeViewState:button enabled:NO];
    if ([button.titleLabel.text isEqualToString:@"STOP"]) {
        if ([FPWCSApi2 getSessions].count) {
            FPWCSApi2Stream *stream;
            for (FPWCSApi2Stream *s in [[FPWCSApi2 getSessions][0] getStreams]) {
                if ([[s getName] isEqualToString:_localStreamName.text]) {
                    stream = s;
                    break;
                }
            }
            if (!stream) {
                NSLog(@"Stop publishing, nothing to stop");
                [self onUnpublished];
                return;
            }
            [stream stop];
        } else {
            NSLog(@"Stop publishing, no session");
            [self onUnpublished];
        }
    } else {
        if ([FPWCSApi2 getSessions].count) {
            [self changeViewState:_localStreamName enabled:NO];
            [self publishStream];
        } else {
            NSLog(@"Start publishing, no session");
            [self onUnpublished];
        }
    }
}

- (void)playButton:(UIButton *)button {
    [self changeViewState:button enabled:NO];
    if ([button.titleLabel.text isEqualToString:@"STOP"]) {
        if ([FPWCSApi2 getSessions].count) {
            FPWCSApi2Stream *stream;
            for (FPWCSApi2Stream *s in [[FPWCSApi2 getSessions][0] getStreams]) {
                if ([[s getName] isEqualToString:_remoteStreamName.text]) {
                    stream = s;
                    break;
                }
            }
            if (!stream) {
                NSLog(@"Stop playing, nothing to stop");
                [self onStopped];
                return;
            }
            [stream stop];
        } else {
            NSLog(@"Stop playing, no session");
            [self onStopped];
        }
    } else {
        if ([FPWCSApi2 getSessions].count) {
            [self changeViewState:_remoteStreamName enabled:NO];
            [self playStream];
        } else {
            NSLog(@"Start playing, no session");
            [self onStopped];
        }
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
        default:
            _connectionStatus.textColor = [UIColor darkTextColor];
            break;
    }
}

- (void)changeStreamStatus:(FPWCSApi2Stream *)stream {
    UILabel *view;
    if ([stream isPublished]) {
        view = _localStreamStatus;
    } else {
        view = _remoteStreamStatus;
    }
    view.text = [FPWCSApi2Model streamStatusToString:[stream getStatus]];
    switch ([stream getStatus]) {
        case kFPWCSStreamStatusFailed:
            view.textColor = [UIColor redColor];
            break;
        case kFPWCSStreamStatusPlaying:
        case kFPWCSStreamStatusPublishing:
            view.textColor = [UIColor greenColor];
            break;
        default:
            view.textColor = [UIColor darkTextColor];
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
    
    _localDisplay = [[RTCEAGLVideoView alloc] init];
    _localDisplay.delegate = self;
    _localDisplay.translatesAutoresizingMaskIntoConstraints = NO;
    
    _remoteDisplay = [[RTCEAGLVideoView alloc] init];
    _remoteDisplay.delegate = self;
    _remoteDisplay.translatesAutoresizingMaskIntoConstraints = NO;
    
    _connectUrl = [self createTextField];
    _connectionStatus = [self createLabelView];
    _connectButton = [self createButton:@"CONNECT"];
    [_connectButton addTarget:self action:@selector(connectButton:) forControlEvents:UIControlEventTouchUpInside];
    
    _localStreamName = [self createTextField];
    _localStreamStatus = [self createLabelView];
    _publishButton = [self createButton:@"PUBLISH"];
    [_publishButton addTarget:self action:@selector(publishButton:) forControlEvents:UIControlEventTouchUpInside];
    
    _remoteStreamName = [self createTextField];
    _remoteStreamStatus = [self createLabelView];
    _playButton = [self createButton:@"PLAY"];
    [_playButton addTarget:self action:@selector(playButton:) forControlEvents:UIControlEventTouchUpInside];
    
    [self.videoContainer addSubview:_localDisplay];
    [self.videoContainer addSubview:_remoteDisplay];
    
    [self.contentView addSubview:_connectUrl];
    [self.contentView addSubview:_connectionStatus];
    [self.contentView addSubview:_connectButton];
    
    [self.contentView addSubview:_localStreamName];
    [self.contentView addSubview:_localStreamStatus];
    [self.contentView addSubview:_publishButton];
    
    [self.contentView addSubview:_remoteStreamName];
    [self.contentView addSubview:_remoteStreamStatus];
    [self.contentView addSubview:_playButton];
    
    [self.contentView addSubview:_videoContainer];
    
    [self.scrollView addSubview:_contentView];
    [self.view addSubview:_scrollView];
    
    //set default values
    _connectUrl.text = @"ws://192.168.88.234:8080/";
    _localStreamName.text = @"test_stream";
    _remoteStreamName.text = @"test_stream";
}

- (UITextField *)createTextField {
    UITextField *textField = [[UITextField alloc] init];
    textField.borderStyle = UITextBorderStyleRoundedRect;
    textField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    [textField setFont:[UIFont boldSystemFontOfSize:12]];
    textField.translatesAutoresizingMaskIntoConstraints = NO;
    [textField setReturnKeyType:UIReturnKeyDone];
    textField.delegate = self;
    return textField;

}

- (UITextView *)createTextView {
    UITextView *textView = [[UITextView alloc] init];
    [textView setFont:[UIFont boldSystemFontOfSize:12]];
    textView.translatesAutoresizingMaskIntoConstraints = NO;
    textView.textAlignment = NSTextAlignmentCenter;
    textView.editable = NO;
    textView.text = @"NO STATUS";
    return textView;
}

- (UILabel *)createLabelView {
    UILabel *textView = [[UILabel alloc] init];
    [textView setFont:[UIFont boldSystemFontOfSize:12]];
    textView.translatesAutoresizingMaskIntoConstraints = NO;
    textView.textAlignment = NSTextAlignmentCenter;
    textView.text = @"NO STATUS";
    return textView;
}

- (UIButton *)createButton:(NSString *)title {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    [button setBackgroundColor:[UIColor lightGrayColor]];
    [button.layer setBorderWidth:2.0];
    [button.layer setCornerRadius:6.0];
    [button setTitle:title forState:UIControlStateNormal];
    button.translatesAutoresizingMaskIntoConstraints = NO;
    return button;
}

- (void)setupLayout {
    NSDictionary *views = @{
                            @"connectUrl": _connectUrl,
                            @"connectionStatus": _connectionStatus,
                            @"connectButton": _connectButton,
                            @"localStreamName": _localStreamName,
                            @"localStreamStatus": _localStreamStatus,
                            @"publishButton": _publishButton,
                            @"remoteStreamName": _remoteStreamName,
                            @"remoteStreamStatus": _remoteStreamStatus,
                            @"playButton": _playButton,
                            @"localDisplay": _localDisplay,
                            @"remoteDisplay": _remoteDisplay,
                            @"videoContainer": _videoContainer,
                            @"contentView": _contentView,
                            @"scrollView": _scrollView
                            };
    
    NSNumber *videoHeight = @320;
    //custom videoHeight for pads
    if ( UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad )
    {
        NSLog(@"Set video container height for pads");
        videoHeight = @640;
    }
    
    NSDictionary *metrics = @{
                              @"buttonHeight": @30,
                              @"statusHeight": @30,
                              @"inputFieldHeight": @30,
                              @"videoHeight": videoHeight,
                              @"vSpacing": @20,
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
    
    _localDisplayConstraints = [[NSMutableArray alloc] init];
    _remoteDisplayConstraints = [[NSMutableArray alloc] init];
    
    //set height size
    setConstraint(_connectUrl, @"V:[connectUrl(inputFieldHeight)]", 0);
    setConstraint(_localStreamName, @"V:[localStreamName(inputFieldHeight)]", 0);
    setConstraint(_remoteStreamName, @"V:[remoteStreamName(inputFieldHeight)]", 0);
    setConstraint(_connectionStatus, @"V:[connectionStatus(statusHeight)]", 0);
    setConstraint(_localStreamStatus, @"V:[localStreamStatus(statusHeight)]", 0);
    setConstraint(_remoteStreamStatus, @"V:[remoteStreamStatus(statusHeight)]", 0);
    setConstraint(_connectButton, @"V:[connectButton(buttonHeight)]", 0);
    setConstraint(_publishButton, @"V:[publishButton(buttonHeight)]", 0);
    setConstraint(_playButton, @"V:[playButton(buttonHeight)]", 0);
    setConstraint(_videoContainer, @"V:[videoContainer(videoHeight)]", 0);
    
    //set width related to super view
    setConstraint(_contentView, @"H:|-hSpacing-[connectUrl]-hSpacing-|", 0);
    setConstraint(_contentView, @"H:|-hSpacing-[localStreamName]-hSpacing-|", 0);
    setConstraint(_contentView, @"H:|-hSpacing-[remoteStreamName]-hSpacing-|", 0);
    setConstraint(_contentView, @"H:|-hSpacing-[connectionStatus]-hSpacing-|", 0);
    setConstraint(_contentView, @"H:|-hSpacing-[localStreamStatus]-hSpacing-|", 0);
    setConstraint(_contentView, @"H:|-hSpacing-[remoteStreamStatus]-hSpacing-|", 0);
    setConstraint(_contentView, @"H:|-hSpacing-[connectButton]-hSpacing-|",0);
    setConstraint(_contentView, @"H:|-hSpacing-[publishButton]-hSpacing-|", 0);
    setConstraint(_contentView, @"H:|-hSpacing-[playButton]-hSpacing-|", 0);
    setConstraint(_contentView, @"H:|-hSpacing-[videoContainer]-hSpacing-|", 0);
    
    //local display max width and height
    setConstraintWithItem(_videoContainer, _localDisplay, _videoContainer, NSLayoutAttributeHeight, NSLayoutRelationLessThanOrEqual, NSLayoutAttributeHeight, 1.0, 0);
    setConstraintWithItem(_videoContainer, _localDisplay, _videoContainer, NSLayoutAttributeWidth, NSLayoutRelationLessThanOrEqual, NSLayoutAttributeWidth, 0.48, 0);
    
    //local display aspect ratio
    NSLayoutConstraint *localARConstraint = setConstraintWithItem(_localDisplay, _localDisplay, _localDisplay, NSLayoutAttributeWidth, NSLayoutRelationEqual, NSLayoutAttributeHeight, 640.0/480.0, 0);
    [_localDisplayConstraints addObject:localARConstraint];
    
    //remote display max width and height
    setConstraintWithItem(_videoContainer, _remoteDisplay, _videoContainer, NSLayoutAttributeHeight, NSLayoutRelationLessThanOrEqual, NSLayoutAttributeHeight, 1.0, 0);
    setConstraintWithItem(_videoContainer, _remoteDisplay, _videoContainer, NSLayoutAttributeWidth, NSLayoutRelationLessThanOrEqual, NSLayoutAttributeWidth, 0.48, 0);
    
    //remote display aspect ratio
    NSLayoutConstraint *remoteARConstraint = setConstraintWithItem(_remoteDisplay, _remoteDisplay, _remoteDisplay, NSLayoutAttributeWidth, NSLayoutRelationEqual, NSLayoutAttributeHeight, 640.0/480.0, 0);
    [_remoteDisplayConstraints addObject:remoteARConstraint];
    
    //position video views inside video container
    setConstraint(_videoContainer, @"H:|[localDisplay][remoteDisplay]|", NSLayoutFormatAlignAllTop);
    setConstraint(_videoContainer, @"V:|[localDisplay]", 0);
    
    setConstraint(self.contentView, @"V:|-50-[connectUrl]-vSpacing-[connectionStatus]-vSpacing-[connectButton]-vSpacing-[localStreamName]-vSpacing-[localStreamStatus]-vSpacing-[publishButton]-vSpacing-[remoteStreamName]-vSpacing-[remoteStreamStatus]-vSpacing-[playButton]-vSpacing-[videoContainer]-vSpacing-|", 0);
    
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
    if (videoView == _localDisplay) {
        NSLog(@"Size of local video %fx%f", size.width, size.height);
    } else {
        NSLog(@"Size of remote video %fx%f", size.width, size.height);
    }
    if (videoView == _localDisplay) {
        [_localDisplay removeConstraints:_localDisplayConstraints];
        [_localDisplayConstraints removeAllObjects];
        NSLayoutConstraint *constraint =[NSLayoutConstraint
                                         constraintWithItem:_localDisplay
                                         attribute:NSLayoutAttributeWidth
                                         relatedBy:NSLayoutRelationEqual
                                         toItem:_localDisplay
                                         attribute:NSLayoutAttributeHeight
                                         multiplier:size.width/size.height
                                         constant:0.0f];
        [_localDisplayConstraints addObject:constraint];
        [_localDisplay addConstraints:_localDisplayConstraints];
    } else {
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
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

@end
