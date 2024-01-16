//
//  ViewController.m
//  WCSApiExample
//
//  Created by flashphoner on 24/11/2015.
//  Copyright © 2015 flashphoner. All rights reserved.
//

#import "ViewController.h"
#import "WCSUtil.h"
#import <AVFoundation/AVFoundation.h>
#import <FPWCSApi2/FPWCSApi2.h>

@interface ViewController ()

@end

@implementation ViewController

FPWCSApi2Stream *player1Stream;
FPWCSApi2Stream *player2Stream;

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

- (FPWCSApi2Stream *)play1Stream {
    FPWCSApi2Session *session = [FPWCSApi2 getSessions][0];
    FPWCSApi2StreamOptions *options = [[FPWCSApi2StreamOptions alloc] init];
    options.name = _player1StreamName.text;
    options.display = _player1Display;
    NSError *error;
    player1Stream = [session createStream:options error:nil];
    if (!player1Stream) {
        UIAlertController * alert = [UIAlertController
                                     alertControllerWithTitle:@"Failed to play"
                                     message:error.localizedDescription
                                     preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction* okButton = [UIAlertAction
                                   actionWithTitle:@"Ok"
                                   style:UIAlertActionStyleDefault
                                   handler:^(UIAlertAction * action) {
                                       [self onStopped1];
                                   }];
        
        [alert addAction:okButton];
        [self presentViewController:alert animated:YES completion:nil];
        return nil;
    }
    [player1Stream on:kFPWCSStreamStatusPlaying callback:^(FPWCSApi2Stream *rStream){
        [self changeStream1Status:rStream];
        [self onPlaying1:rStream];
    }];
    
    [player1Stream on:kFPWCSStreamStatusNotEnoughtBandwidth callback:^(FPWCSApi2Stream *rStream){
        NSLog(@"Not enough bandwidth stream %@, consider using lower video resolution or bitrate. Bandwidth %ld bitrate %ld", [rStream getName], [rStream getNetworkBandwidth] / 1000, [rStream getRemoteBitrate] / 1000);
        [self changeStream1Status:rStream];
    }];
    
    [player1Stream on:kFPWCSStreamStatusStopped callback:^(FPWCSApi2Stream *rStream){
        [self changeStream1Status:rStream];
        [self onStopped1];
    }];
    [player1Stream on:kFPWCSStreamStatusFailed callback:^(FPWCSApi2Stream *rStream){
        [self changeStream1Status:rStream];
        [self onStopped1];
    }];
    if(![player1Stream play:&error]) {
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
    return player1Stream;
}

- (FPWCSApi2Stream *)play2Stream {
    FPWCSApi2Session *session = [FPWCSApi2 getSessions][0];
    FPWCSApi2StreamOptions *options = [[FPWCSApi2StreamOptions alloc] init];
    options.name = _player2StreamName.text;
    options.display = _player2Display;
    NSError *error;
    player2Stream = [session createStream:options error:nil];
    if (!player2Stream) {
        UIAlertController * alert = [UIAlertController
                                     alertControllerWithTitle:@"Failed to play"
                                     message:error.localizedDescription
                                     preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction* okButton = [UIAlertAction
                                   actionWithTitle:@"Ok"
                                   style:UIAlertActionStyleDefault
                                   handler:^(UIAlertAction * action) {
                                       [self onStopped2];
                                   }];
        
        [alert addAction:okButton];
        [self presentViewController:alert animated:YES completion:nil];
        return nil;
    }
    [player2Stream on:kFPWCSStreamStatusPlaying callback:^(FPWCSApi2Stream *rStream){
        [self changeStream2Status:rStream];
        [self onPlaying2:rStream];
    }];
    
    [player2Stream on:kFPWCSStreamStatusNotEnoughtBandwidth callback:^(FPWCSApi2Stream *rStream){
        NSLog(@"Not enough bandwidth stream %@, consider using lower video resolution or bitrate. Bandwidth %ld bitrate %ld", [rStream getName], [rStream getNetworkBandwidth] / 1000, [rStream getRemoteBitrate] / 1000);
        [self changeStream2Status:rStream];
    }];
    
    [player2Stream on:kFPWCSStreamStatusStopped callback:^(FPWCSApi2Stream *rStream){
        [self changeStream2Status:rStream];
        [self onStopped2];
    }];
    [player2Stream on:kFPWCSStreamStatusFailed callback:^(FPWCSApi2Stream *rStream){
        [self changeStream2Status:rStream];
        [self onStopped2];
    }];
    if(![player2Stream play:&error]) {
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
    return player2Stream;
}


//session and stream status handlers
- (void)onConnected:(FPWCSApi2Session *)session {
    [_connectButton setTitle:@"DISCONNECT" forState:UIControlStateNormal];
    [self changeViewState:_connectButton enabled:YES];
    [self onStopped1];
    [self onStopped2];
}

- (void)onDisconnected {
    [_connectButton setTitle:@"CONNECT" forState:UIControlStateNormal];
    [self changeViewState:_connectButton enabled:YES];
    [self changeViewState:_connectUrl enabled:YES];
    [self onStopped1];
    [self onStopped2];
}

- (void)onPlaying1:(FPWCSApi2Stream *)stream {
    [_player1Button setTitle:@"STOP" forState:UIControlStateNormal];
    [self changeViewState:_player1Button enabled:YES];
}

- (void)onStopped1 {
    [_player1Button setTitle:@"PLAY" forState:UIControlStateNormal];
    if ([FPWCSApi2 getSessions].count && [[FPWCSApi2 getSessions][0] getStatus] == kFPWCSSessionStatusEstablished) {
        [self changeViewState:_player1Button enabled:YES];
        [self changeViewState:_player1StreamName enabled:YES];
    } else {
        [self changeViewState:_player1Button enabled:NO];
        [self changeViewState:_player1StreamName enabled:NO];
    }
    [_player1Display renderFrame:nil];
}

- (void)onPlaying2:(FPWCSApi2Stream *)stream {
    [_player2Button setTitle:@"STOP" forState:UIControlStateNormal];
    [self changeViewState:_player2Button enabled:YES];
}

- (void)onStopped2 {
    [_player2Button setTitle:@"PLAY" forState:UIControlStateNormal];
    if ([FPWCSApi2 getSessions].count && [[FPWCSApi2 getSessions][0] getStatus] == kFPWCSSessionStatusEstablished) {
        [self changeViewState:_player2Button enabled:YES];
        [self changeViewState:_player2StreamName enabled:YES];
    } else {
        [self changeViewState:_player2Button enabled:NO];
        [self changeViewState:_player2StreamName enabled:NO];
    }
    [_player2Display renderFrame:nil];
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

- (void)player1Button:(UIButton *)button {
    [self changeViewState:button enabled:NO];
    if ([button.titleLabel.text isEqualToString:@"STOP"]) {
        if ([FPWCSApi2 getSessions].count) {
            NSError *error;
            [player1Stream stop:&error];
        } else {
            NSLog(@"Stop playing, no session");
            [self onStopped1];
        }
    } else {
        if ([FPWCSApi2 getSessions].count) {
            [self changeViewState:_player1StreamName enabled:NO];
            [self play1Stream];
        } else {
            NSLog(@"Start playing, no session");
            [self onStopped1];
        }
    }
}

- (void)player2Button:(UIButton *)button {
    [self changeViewState:button enabled:NO];
    if ([button.titleLabel.text isEqualToString:@"STOP"]) {
        if ([FPWCSApi2 getSessions].count) {
            NSError *error;
            [player2Stream stop:&error];
        } else {
            NSLog(@"Stop playing, no session");
            [self onStopped2];
        }
    } else {
        if ([FPWCSApi2 getSessions].count) {
            [self changeViewState:_player2StreamName enabled:NO];
            [self play2Stream];
        } else {
            NSLog(@"Start playing, no session");
            [self onStopped2];
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

- (void)changeStream1Status:(FPWCSApi2Stream *)stream {
    _player1Status.text = [FPWCSApi2Model streamStatusToString:[stream getStatus]];
    switch ([stream getStatus]) {
        case kFPWCSStreamStatusFailed:
            _player1Status.textColor = [UIColor redColor];
            break;
        case kFPWCSStreamStatusPlaying:
        case kFPWCSStreamStatusPublishing:
            _player1Status.textColor = [UIColor greenColor];
            break;
        default:
            _player1Status.textColor = [UIColor darkTextColor];
            break;
    }
}

- (void)changeStream2Status:(FPWCSApi2Stream *)stream {
    _player2Status.text = [FPWCSApi2Model streamStatusToString:[stream getStatus]];
    switch ([stream getStatus]) {
        case kFPWCSStreamStatusFailed:
            _player2Status.textColor = [UIColor redColor];
            break;
        case kFPWCSStreamStatusPlaying:
        case kFPWCSStreamStatusPublishing:
            _player2Status.textColor = [UIColor greenColor];
            break;
        default:
            _player2Status.textColor = [UIColor darkTextColor];
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
    
    _player1Container = [[UIView alloc] init];
    _player1Container.translatesAutoresizingMaskIntoConstraints = NO;
    
    _player2Container = [[UIView alloc] init];
    _player2Container.translatesAutoresizingMaskIntoConstraints = NO;
    
    _player1Display = [[RTCMTLVideoView alloc] init];
    _player1Display.delegate = self;
    _player1Display.translatesAutoresizingMaskIntoConstraints = NO;
    
    _player2Display = [[RTCMTLVideoView alloc] init];
    _player2Display.delegate = self;
    _player2Display.translatesAutoresizingMaskIntoConstraints = NO;
    
    _connectUrl = [WCSViewUtil createTextField:self];
    _connectionStatus = [WCSViewUtil createLabelView];
    _connectButton = [WCSViewUtil createButton:@"CONNECT"];
    [_connectButton addTarget:self action:@selector(connectButton:) forControlEvents:UIControlEventTouchUpInside];
    
    _player1StreamName = [WCSViewUtil createTextField:self];
    _player1Status = [WCSViewUtil createLabelView];
    _player1Button = [WCSViewUtil createButton:@"PLAY"];
    [_player1Button addTarget:self action:@selector(player1Button:) forControlEvents:UIControlEventTouchUpInside];
    
    _player2StreamName = [WCSViewUtil createTextField:self];
    _player2Status = [WCSViewUtil createLabelView];
    _player2Button = [WCSViewUtil createButton:@"PLAY"];
    [_player2Button addTarget:self action:@selector(player2Button:) forControlEvents:UIControlEventTouchUpInside];
    
    [self.videoContainer addSubview:_player1Display];
    [self.videoContainer addSubview:_player2Display];
    
    [self.contentView addSubview:_videoContainer];
    
    [self.player1Container addSubview:_player1StreamName];
    [self.player1Container addSubview:_player1Status];
    [self.player1Container addSubview:_player1Button];
    [self.contentView addSubview:_player1Container];

    [self.player2Container addSubview:_player2StreamName];
    [self.player2Container addSubview:_player2Status];
    [self.player2Container addSubview:_player2Button];
    [self.contentView addSubview:_player2Container];
    
    [self.contentView addSubview:_connectUrl];
    [self.contentView addSubview:_connectionStatus];
    [self.contentView addSubview:_connectButton];
    
    [self.scrollView addSubview:_contentView];
    [self.view addSubview:_scrollView];
    
    //set default values
    _connectUrl.text = @"wss://demo.flashphoner.com:8443/";
    _player1StreamName.text = @"streamName";
    _player2StreamName.text = @"streamName";
}

- (void)setupLayout {
    NSDictionary *views = @{
                            @"connectUrl": _connectUrl,
                            @"connectionStatus": _connectionStatus,
                            @"connectButton": _connectButton,
                            @"player1Container": _player1Container,
                            @"player1StreamName": _player1StreamName,
                            @"player1Status": _player1Status,
                            @"player1Button": _player1Button,
                            @"player2Container": _player2Container,
                            @"player2StreamName": _player2StreamName,
                            @"player2Status": _player2Status,
                            @"player2Button": _player2Button,
                            @"player1Display": _player1Display,
                            @"player2Display": _player2Display,
                            @"videoContainer": _videoContainer,
                            @"contentView": _contentView,
                            @"scrollView": _scrollView
                            };
    
    NSNumber *videoHeight = @100;
    //custom videoHeight for pads
    if ( UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ) {
        NSLog(@"Set video container height for pads");
        videoHeight = @320;
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
    setConstraint(_videoContainer, @"V:[videoContainer(videoHeight)]", 0);
    setConstraint(_player1StreamName, @"V:[player1StreamName(inputFieldHeight)]", 0);
    setConstraint(_player1Status, @"V:[player1Status(statusHeight)]", 0);
    setConstraint(_player1Button, @"V:[player1Button(buttonHeight)]", 0);
    setConstraint(_player2StreamName, @"V:[player2StreamName(inputFieldHeight)]", 0);
    setConstraint(_player2Status, @"V:[player2Status(statusHeight)]", 0);
    setConstraint(_player2Button, @"V:[player2Button(buttonHeight)]", 0);
    setConstraint(_connectionStatus, @"V:[connectionStatus(statusHeight)]", 0);
    setConstraint(_connectUrl, @"V:[connectUrl(inputFieldHeight)]", 0);
    setConstraint(_connectButton, @"V:[connectButton(buttonHeight)]", 0);
    
    //set width related to super view
    setConstraint(_contentView, @"H:|-hSpacing-[videoContainer]-hSpacing-|", 0);
    setConstraint(_player1Container, @"H:|-hSpacing-[player1StreamName]-hSpacing-|", 0);
    setConstraint(_player1Container, @"H:|-hSpacing-[player1Status]-hSpacing-|", 0);
    setConstraint(_player1Container, @"H:|-hSpacing-[player1Button]-hSpacing-|", 0);
    
    setConstraintWithItem(_contentView, _player1Container, _contentView, NSLayoutAttributeHeight, NSLayoutRelationLessThanOrEqual, NSLayoutAttributeHeight, 1.0, 0);
    setConstraintWithItem(_contentView, _player1Container, _contentView, NSLayoutAttributeWidth, NSLayoutRelationLessThanOrEqual, NSLayoutAttributeWidth, 0.48, 0);
    
    setConstraint(_player1Container, @"V:|-vSpacing-[player1StreamName]-vSpacing-[player1Status]-vSpacing-[player1Button]-vSpacing-|", 0);

    
    setConstraint(_player2Container, @"H:|-hSpacing-[player2StreamName]-hSpacing-|", 0);
    setConstraint(_player2Container, @"H:|-hSpacing-[player2Status]-hSpacing-|", 0);
    setConstraint(_player2Container, @"H:|-hSpacing-[player2Button]-hSpacing-|", 0);
    setConstraintWithItem(_contentView, _player2Container, _contentView, NSLayoutAttributeHeight, NSLayoutRelationLessThanOrEqual, NSLayoutAttributeHeight, 1.0, 0);
    setConstraintWithItem(_contentView, _player2Container, _contentView, NSLayoutAttributeWidth, NSLayoutRelationLessThanOrEqual, NSLayoutAttributeWidth, 0.48, 0);
    setConstraint(_player2Container, @"V:|-vSpacing-[player2StreamName]-vSpacing-[player2Status]-vSpacing-[player2Button]-vSpacing-|", 0);
    
    setConstraint(_contentView, @"H:|-hSpacing-[player1Container][player2Container]-hSpacing-|", NSLayoutFormatAlignAllTop);
    setConstraint(_contentView, @"H:|-hSpacing-[connectionStatus]-hSpacing-|", 0);
    setConstraint(_contentView, @"H:|-hSpacing-[connectButton]-hSpacing-|",0);
    setConstraint(_contentView, @"H:|-hSpacing-[connectUrl]-hSpacing-|", 0);
    
    //player1 display max width and height
    setConstraintWithItem(_videoContainer, _player1Display, _videoContainer, NSLayoutAttributeHeight, NSLayoutRelationLessThanOrEqual, NSLayoutAttributeHeight, 1.0, 0);
    setConstraintWithItem(_videoContainer, _player1Display, _videoContainer, NSLayoutAttributeWidth, NSLayoutRelationLessThanOrEqual, NSLayoutAttributeWidth, 0.48, 0);
    
    //player2 display max width and height
    setConstraintWithItem(_videoContainer, _player2Display, _videoContainer, NSLayoutAttributeHeight, NSLayoutRelationLessThanOrEqual, NSLayoutAttributeHeight, 1.0, 0);
    setConstraintWithItem(_videoContainer, _player2Display, _videoContainer, NSLayoutAttributeWidth, NSLayoutRelationLessThanOrEqual, NSLayoutAttributeWidth, 0.48, 0);
    
    //position video views inside video container
    setConstraint(_videoContainer, @"H:|[player1Display][player2Display]|", NSLayoutFormatAlignAllTop);
    setConstraint(_videoContainer, @"V:|[player1Display]", 0);
    
    setConstraint(_contentView, @"V:|-50-[videoContainer]-vSpacing-[player1Container]-vSpacing-[connectUrl]-vSpacing-[connectionStatus]-vSpacing-[connectButton]-vSpacing-|", 0);
    
    //content view width
    setConstraintWithItem(self.view, _contentView, self.view, NSLayoutAttributeWidth, NSLayoutRelationEqual, NSLayoutAttributeWidth, 1.0, 0);
    
    //position content and scroll views
    setConstraint(self.view, @"V:|[contentView]|", 0);
    setConstraint(self.view, @"H:|[contentView]|", 0);
    setConstraint(self.view, @"V:|[scrollView]|", 0);
    setConstraint(self.view, @"H:|[scrollView]|", 0);
    
    _player1DisplayConstraints = [[NSMutableArray alloc] init];
    _player2DisplayConstraints = [[NSMutableArray alloc] init];
    
    //player1 display aspect ratio
    NSLayoutConstraint *localARConstraint = setConstraintWithItem(_player1Display, _player1Display, _player1Display, NSLayoutAttributeWidth, NSLayoutRelationEqual, NSLayoutAttributeHeight, 640.0/480.0, 0);
    [_player1DisplayConstraints addObject:localARConstraint];
    
    //player2 display aspect ratio
    NSLayoutConstraint *remoteARConstraint = setConstraintWithItem(_player2Display, _player2Display, _player2Display, NSLayoutAttributeWidth, NSLayoutRelationEqual, NSLayoutAttributeHeight, 640.0/480.0, 0);
    [_player2DisplayConstraints addObject:remoteARConstraint];

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - RTCMTLVideoViewDelegate

- (void)videoView:(RTCMTLVideoView*)videoView didChangeVideoSize:(CGSize)size {
    if (videoView == _player1Display) {
        NSLog(@"Size of local video %fx%f", size.width, size.height);
    } else {
        NSLog(@"Size of remote video %fx%f", size.width, size.height);
    }
    if (videoView == _player1Display) {
        [_player1Display removeConstraints:_player1DisplayConstraints];
        [_player1DisplayConstraints removeAllObjects];
        NSLayoutConstraint *constraint =[NSLayoutConstraint
                                         constraintWithItem:_player1Display
                                         attribute:NSLayoutAttributeWidth
                                         relatedBy:NSLayoutRelationEqual
                                         toItem:_player1Display
                                         attribute:NSLayoutAttributeHeight
                                         multiplier:size.width/size.height
                                         constant:0.0f];
        [_player1DisplayConstraints addObject:constraint];
        [_player1Display addConstraints:_player1DisplayConstraints];
    } else {
        [_player2Display removeConstraints:_player2DisplayConstraints];
        [_player2DisplayConstraints removeAllObjects];
        NSLayoutConstraint *constraint =[NSLayoutConstraint
                                         constraintWithItem:_player2Display
                                         attribute:NSLayoutAttributeWidth
                                         relatedBy:NSLayoutRelationEqual
                                         toItem:_player2Display
                                         attribute:NSLayoutAttributeHeight
                                         multiplier:size.width/size.height
                                         constant:0.0f];
        [_player2DisplayConstraints addObject:constraint];
        [_player2Display addConstraints:_player2DisplayConstraints];
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

@end
