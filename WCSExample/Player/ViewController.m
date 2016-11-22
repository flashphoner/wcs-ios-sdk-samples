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
    
    [stream on:kFPWCSStreamStatusStopped callback:^(FPWCSApi2Stream *rStream){
        [self changeStreamStatus:rStream];
        [self onStopped];
    }];
    [stream on:kFPWCSStreamStatusFailed callback:^(FPWCSApi2Stream *rStream){
        [self changeStreamStatus:rStream];
        [self onStopped];
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
    
    _remoteDisplay = [[RTCEAGLVideoView alloc] init];
    _remoteDisplay.delegate = self;
    _remoteDisplay.translatesAutoresizingMaskIntoConstraints = NO;
    
    _connectUrl = [self createTextField];
    
    _playStreamLabel = [self createInfoLabel:@"Play Stream"];
    _remoteStreamName = [self createTextField];
    _status = [self createLabelView];
    _startButton = [self createButton:@"PLAY"];
    [_startButton addTarget:self action:@selector(startButton:) forControlEvents:UIControlEventTouchUpInside];
    
    [self.videoContainer addSubview:_remoteDisplay];
    
    [self.contentView addSubview:_connectUrl];
    [self.contentView addSubview:_playStreamLabel];
    [self.contentView addSubview:_remoteStreamName];
    [self.contentView addSubview:_status];
    [self.contentView addSubview:_startButton];
    
    [self.contentView addSubview:_videoContainer];
    
    [self.scrollView addSubview:_contentView];
    [self.view addSubview:_scrollView];
    
    //set default values
    _connectUrl.text = @"wss://87.226.225.59:8443/";
    _remoteStreamName.text = @"streamName";
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

- (UILabel *)createInfoLabel:(NSString *)infoText {
    UILabel *label = [[UILabel alloc] init];
    [label setFont:[UIFont boldSystemFontOfSize:12]];
    label.translatesAutoresizingMaskIntoConstraints = NO;
    label.textAlignment = NSTextAlignmentLeft;
    label.text = infoText;
    return label;
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
                            @"playStreamLabel": _playStreamLabel,
                            @"remoteStreamName": _remoteStreamName,
                            @"status": _status,
                            @"startButton": _startButton,
                            @"remoteDisplay": _remoteDisplay,
                            @"videoContainer": _videoContainer,
                            @"contentView": _contentView,
                            @"scrollView": _scrollView
                            };
    
    NSNumber *videoHeight = @320;
    //custom videoHeight for pads
    if ( UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ) {
        NSLog(@"Set video container height for pads");
        videoHeight = @640;
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
    
    _remoteDisplayConstraints = [[NSMutableArray alloc] init];
    
    //set height size
    setConstraint(_connectUrl, @"V:[connectUrl(inputFieldHeight)]", 0);
    setConstraint(_playStreamLabel, @"V:[playStreamLabel(labelHeight)]", 0);
    setConstraint(_remoteStreamName, @"V:[remoteStreamName(inputFieldHeight)]", 0);
    setConstraint(_status, @"V:[status(statusHeight)]", 0);
    setConstraint(_startButton, @"V:[startButton(buttonHeight)]", 0);
    setConstraint(_videoContainer, @"V:[videoContainer(videoHeight)]", 0);
    
    //set width related to super view
    setConstraint(_contentView, @"H:|-hSpacing-[connectUrl]-hSpacing-|", 0);
    setConstraint(_contentView, @"H:|-hSpacing-[playStreamLabel]-hSpacing-|", 0);
    setConstraint(_contentView, @"H:|-hSpacing-[remoteStreamName]-hSpacing-|", 0);
    setConstraint(_contentView, @"H:|-hSpacing-[status]-hSpacing-|", 0);
    setConstraint(_contentView, @"H:|-hSpacing-[startButton]-hSpacing-|", 0);
    setConstraint(_contentView, @"H:|-hSpacing-[videoContainer]-hSpacing-|", 0);
    
    //remote display max width and height
    setConstraintWithItem(_videoContainer, _remoteDisplay, _videoContainer, NSLayoutAttributeHeight, NSLayoutRelationLessThanOrEqual, NSLayoutAttributeHeight, 1.0, 0);
    setConstraintWithItem(_videoContainer, _remoteDisplay, _videoContainer, NSLayoutAttributeWidth, NSLayoutRelationLessThanOrEqual, NSLayoutAttributeWidth, 1.0, 0);
    
    //remote display aspect ratio
    NSLayoutConstraint *remoteARConstraint = setConstraintWithItem(_remoteDisplay, _remoteDisplay, _remoteDisplay, NSLayoutAttributeWidth, NSLayoutRelationEqual, NSLayoutAttributeHeight, 640.0/480.0, 0);
    [_remoteDisplayConstraints addObject:remoteARConstraint];
    
    //position video views inside video container
    setConstraint(_videoContainer, @"H:|[remoteDisplay]|", NSLayoutFormatAlignAllTop);
    setConstraint(_videoContainer, @"V:|[remoteDisplay]|", 0);
    
    setConstraint(self.contentView, @"V:|-50-[connectUrl]-vSpacing-[playStreamLabel]-vSpacing-[remoteStreamName]-vSpacing-[status]-vSpacing-[startButton]-vSpacing-[videoContainer]-vSpacing-|", 0);
    
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