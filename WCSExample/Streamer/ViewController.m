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

NSString *streamName;
FPWCSApi2Session *session;
FPWCSApi2Stream *publishStream;
FPWCSApi2Stream *playStream;


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
    NSURL *url =[[NSURL alloc] initWithString:_connectUrl.text];
    options.urlServer = [NSString stringWithFormat:@"%@://%@:%@", url.scheme, url.host, url.port];
    streamName = [url.path.stringByDeletingPathExtension stringByReplacingOccurrencesOfString: @"/" withString:@""];
    options.appKey = @"defaultApp";
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
    options.name = streamName;
    options.display = _videoView.local;
    if ( UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ) {
        options.constraints = [[FPWCSApi2MediaConstraints alloc] initWithAudio:YES videoWidth:640 videoHeight:480 videoFps:15];
    }
    NSError *error;
    publishStream = [session createStream:options error:&error];
    if (!publishStream) {
        UIAlertController * alert = [UIAlertController
                                     alertControllerWithTitle:@"Failed to publish"
                                     message:error.localizedDescription
                                     preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction* okButton = [UIAlertAction
                                   actionWithTitle:@"Ok"
                                   style:UIAlertActionStyleDefault
                                   handler:^(UIAlertAction * action) {
                                       [self onUnpublished];
                                   }];
        
        [alert addAction:okButton];
        [self presentViewController:alert animated:YES completion:nil];
        return nil;
    }
    [publishStream on:kFPWCSStreamStatusPublishing callback:^(FPWCSApi2Stream *rStream){
        [self changeStreamStatus:rStream];
        [self onPublishing:rStream];
    }];

    [publishStream on:kFPWCSStreamStatusUnpublished callback:^(FPWCSApi2Stream *rStream){
        [self changeStreamStatus:rStream];
        [self onUnpublished];
    }];
    
    [publishStream on:kFPWCSStreamStatusFailed callback:^(FPWCSApi2Stream *rStream){
        [self changeStreamStatus:rStream];
        [self onUnpublished];
    }];
    if(![publishStream publish:&error]) {
        UIAlertController * alert = [UIAlertController
                                     alertControllerWithTitle:@"Failed to publish"
                                     message:error.localizedDescription
                                     preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction* okButton = [UIAlertAction
                                    actionWithTitle:@"Ok"
                                    style:UIAlertActionStyleDefault
                                    handler:^(UIAlertAction * action) {
                                        [self onUnpublished];
                                    }];
        
        [alert addAction:okButton];
        [self presentViewController:alert animated:YES completion:nil];
    }
    return publishStream;
}

- (FPWCSApi2Stream *)playStream {
    FPWCSApi2Session *session = [FPWCSApi2 getSessions][0];
    FPWCSApi2StreamOptions *options = [[FPWCSApi2StreamOptions alloc] init];
    options.name = streamName;
    options.display = _videoView.remote;
    NSError *error;
    playStream = [session createStream:options error:nil];
    if (!playStream) {
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
    [playStream on:kFPWCSStreamStatusPlaying callback:^(FPWCSApi2Stream *rStream){
        [self changeStreamStatus:rStream];
        [self onPlaying:rStream];
    }];
    
    [playStream on:kFPWCSStreamStatusNotEnoughtBandwidth callback:^(FPWCSApi2Stream *rStream){
        NSLog(@"Not enough bandwidth stream %@, consider using lower video resolution or bitrate. Bandwidth %ld bitrate %ld", [rStream getName], [rStream getNetworkBandwidth] / 1000, [rStream getRemoteBitrate] / 1000);
        [self changeStreamStatus:rStream];
    }];
    
    [playStream on:kFPWCSStreamStatusStopped callback:^(FPWCSApi2Stream *rStream){
        [self changeStreamStatus:rStream];
        [self onStopped];
    }];
    [playStream on:kFPWCSStreamStatusFailed callback:^(FPWCSApi2Stream *rStream){
        [self changeStreamStatus:rStream];
        [self onStopped];
    }];
    if(![playStream play:&error]) {
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
    return playStream;
}

//session and stream status handlers
- (void)onConnected:(FPWCSApi2Session *)session {
    [_connectButton setTitle:@"STOP" forState:UIControlStateNormal];
   // [self changeViewState:_connectButton enabled:YES];
    [self publishStream];
}

- (void)onDisconnected {
    [_connectButton setTitle:@"START" forState:UIControlStateNormal];
    [self changeViewState:_connectButton enabled:YES];
    [self changeViewState:_connectUrl enabled:YES];
    [self onUnpublished];
    [self onStopped];
}

- (void)onPublishing:(FPWCSApi2Stream *)stream {
    [self playStream];
}

- (void)onUnpublished {
    [FPWCSApi2 releaseLocalMedia:_videoView.local];
    [_videoView.local renderFrame:nil];
    [session disconnect];
}

- (void)onPlaying:(FPWCSApi2Stream *)stream {
    [_connectButton setTitle:@"STOP" forState:UIControlStateNormal];
    [self changeViewState:_connectButton enabled:YES];
}

- (void)onStopped {
    [FPWCSApi2 releaseLocalMedia:_videoView.remote];
    [_videoView.remote renderFrame:nil];
    [session disconnect];
}

//user interface handlers

- (void)connectButton:(UIButton *)button {
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
        //todo check url is not empty
        [self changeViewState:_connectUrl enabled:NO];
        [self connect];
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
    _connectionStatus.text = [FPWCSApi2Model streamStatusToString:[stream getStatus]];
    switch ([stream getStatus]) {
        case kFPWCSStreamStatusFailed:
            _connectionStatus.textColor = [UIColor redColor];
            break;
        case kFPWCSStreamStatusPlaying:
        case kFPWCSStreamStatusPublishing:
            _connectionStatus.textColor = [UIColor greenColor];
            break;
        default:
            _connectionStatus.textColor = [UIColor darkTextColor];
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
    
    _videoView = [[WCSDoubleVideoView alloc] init];
    
    _connectUrl = [WCSViewUtil createTextField:self];
    _connectionStatus = [WCSViewUtil createLabelView];
    _connectButton = [WCSViewUtil createButton:@"START"];
    [_connectButton addTarget:self action:@selector(connectButton:) forControlEvents:UIControlEventTouchUpInside];

    [self.contentView addSubview:_videoView];
    [self.contentView addSubview:_connectUrl];
    [self.contentView addSubview:_connectionStatus];
    [self.contentView addSubview:_connectButton];
    
    [self.scrollView addSubview:_contentView];
    [self.view addSubview:_scrollView];
    
    //set default values
    _connectUrl.text = @"wss://demo.flashphoner.com:8443/test";
}

- (void)setupLayout {
    NSDictionary *views = @{
                            @"videoView":_videoView,
                            @"connectUrl": _connectUrl,
                            @"connectionStatus": _connectionStatus,
                            @"connectButton": _connectButton,
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
    setConstraint(_videoView, @"V:[videoView(videoHeight)]", 0);
    setConstraint(_connectUrl, @"V:[connectUrl(inputFieldHeight)]", 0);
    setConstraint(_connectionStatus, @"V:[connectionStatus(statusHeight)]", 0);
    setConstraint(_connectButton, @"V:[connectButton(buttonHeight)]", 0);
    
    //set width related to super view
    setConstraint(_contentView, @"H:|-hSpacing-[videoView]-hSpacing-|", 0);
    setConstraint(_contentView, @"H:|-hSpacing-[connectUrl]-hSpacing-|", 0);
    setConstraint(_contentView, @"H:|-hSpacing-[connectionStatus]-hSpacing-|", 0);
    setConstraint(_contentView, @"H:|-hSpacing-[connectButton]-hSpacing-|",0);
    
    setConstraint(self.contentView, @"V:|-50-[videoView]-vSpacing-[connectUrl]-vSpacing-[connectionStatus]-vSpacing-[connectButton]-vSpacing-|", 0);
    
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
