//
//  ViewController.m
//  WCSApiExample
//
//  Created by falshphonr on 24/11/2015.
//  Copyright © 2015 flashphoner. All rights reserved.
//

#import "WCSUtil.h"
#import "ViewController.h"
#import "GPUImageVideoCapturer.h"
#import "GPUImageBeautifyFilter.h"
#import <AVFoundation/AVFoundation.h>
#import <FPWCSApi2/FPWCSApi2.h>

@interface ViewController ()
    @property (nonatomic, strong) GPUImageVideoCamera *videoCamera;
    @property (nonatomic, strong) GPUImageVideoCapturer *videoCapturer;
    @property (nonatomic, strong) GPUImageRawDataOutput *rawDataOutput;
@end

@implementation ViewController


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

- (FPWCSApi2Stream *)publishStream {
    FPWCSApi2Session *session = [FPWCSApi2 getSessions][0];
    FPWCSApi2StreamOptions *options = [[FPWCSApi2StreamOptions alloc] init];
    options.name = _localStreamName.text;
    
    if (!self.videoCamera) {
        self.videoCamera = [[GPUImageVideoCamera alloc] initWithSessionPreset:AVCaptureSessionPreset640x480 cameraPosition:AVCaptureDevicePositionFront];
        self.videoCamera.outputImageOrientation = UIInterfaceOrientationPortrait;
        self.videoCamera.horizontallyMirrorFrontFacingCamera = YES;
    
        self.rawDataOutput = [[GPUImageRawDataOutput alloc] initWithImageSize:CGSizeMake(480, 640) resultsInBGRAFormat:YES];
        self.videoCapturer = [[GPUImageVideoCapturer alloc] init];

        [self.rawDataOutput setNewFrameAvailableBlock:^{
            [_videoCapturer processNewFrame:_rawDataOutput];
        }];
        [self.videoCamera addTarget:_rawDataOutput];
        [self.videoCamera addTarget:_localDisplay];
    }
    
    options.display = _localNativeDisplay;
    options.constraints = [[FPWCSApi2MediaConstraints alloc] initWithAudio:YES videoCapturer:self.videoCapturer];

    NSError *error;
    FPWCSApi2Stream *stream = [session createStream:options error:&error];
    if (!stream) {
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
    if(![stream publish:&error]) {
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
    
    [self.videoCamera startCameraCapture];
    
    return stream;
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
        NSLog(@"Not enough bandwidth stream %@, consider using lower video resolution or bitrate. Bandwidth %ld bitrate %ld", [rStream getName], [rStream getNetworkBandwidth] / 1000, [rStream getRemoteBitrate] / 1000);
        [self changeStreamStatus:rStream];
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
    [self changeViewState:_beautyButton enabled:YES];

}

- (void)onUnpublished {
    [self.videoCamera stopCameraCapture];
    
    [_publishButton setTitle:@"PUBLISH" forState:UIControlStateNormal];
    if ([FPWCSApi2 getSessions].count && [[FPWCSApi2 getSessions][0] getStatus] == kFPWCSSessionStatusEstablished) {
        [self changeViewState:_publishButton enabled:YES];
        [self changeViewState:_localStreamName enabled:YES];
    } else {
        [self changeViewState:_publishButton enabled:NO];
        [self changeViewState:_localStreamName enabled:NO];
    }
    [self changeViewState:_beautyButton enabled:NO];
    [FPWCSApi2 releaseLocalMedia:_localNativeDisplay];
    [_localNativeDisplay renderFrame:nil];
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
                if ([[s getName] isEqualToString:_localStreamName.text] && s.isPublished) {
                    stream = s;
                    break;
                }
            }
            if (!stream) {
                NSLog(@"Stop publishing, nothing to stop");
                [self onUnpublished];
                return;
            }
            NSError *error;
            [stream stop:&error];
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

- (void)beautify:(UIButton *)button {
    if (self.beautifyEnabled) {
        self.beautifyEnabled = NO;
        [_beautyButton setTitle:@"Beautify Enable" forState:UIControlStateNormal];
        [self.videoCamera removeAllTargets];
        [self.videoCamera addTarget:_rawDataOutput];
        [self.videoCamera addTarget:_localDisplay];
    }
    else {
        self.beautifyEnabled = YES;
        [_beautyButton setTitle:@"Beautify Disable" forState:UIControlStateNormal];
        [self.videoCamera removeAllTargets];
        GPUImageBeautifyFilter *beautifyFilter = [[GPUImageBeautifyFilter alloc] init];
        [self.videoCamera addTarget:beautifyFilter];
        [beautifyFilter addTarget:_localDisplay];
        [beautifyFilter addTarget:_rawDataOutput];
    }
}

- (void)playButton:(UIButton *)button {
    [self changeViewState:button enabled:NO];
    if ([button.titleLabel.text isEqualToString:@"STOP"]) {
        if ([FPWCSApi2 getSessions].count) {
            FPWCSApi2Stream *stream;
            for (FPWCSApi2Stream *s in [[FPWCSApi2 getSessions][0] getStreams]) {
                if ([[s getName] isEqualToString:_remoteStreamName.text] && !s.isPublished) {
                    stream = s;
                    break;
                }
            }
            if (!stream) {
                NSLog(@"Stop playing, nothing to stop");
                [self onStopped];
                return;
            }
            NSError *error;
            [stream stop:&error];
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
        {
            view.textColor = [UIColor redColor];
            switch ([stream getStatusInfo]) {
                case kFPWCSStreamStatusInfoSessionDoesNotExist:
                    view.text = @"Actual session does not exist";
                    break;
                case kFPWCSStreamStatusInfoStoppedByPublisherStop:
                    view.text = @"Related publisher stopped its stream or lost connection";
                    break;
                case kFPWCSStreamStatusInfoSessionNotReady:
                    view.text = @"Session is not initialized or terminated on play ordinary stream";
                    break;
                case kFPWCSStreamStatusInfoRtspStreamNotFound:
                    view.text = @"Rtsp stream is not found, agent received '404-Not Found'";
                    break;
                case kFPWCSStreamStatusInfoFailedToConnectToRtspStream:
                    view.text = @"Failed to connect to rtsp stream";
                    break;
                case kFPWCSStreamStatusInfoFileNotFound:
                    view.text = @"File does not exist, check filename";
                    break;
                case kFPWCSStreamStatusInfoFileHasWrongFormat:
                    view.text = @"Failed to play vod stream, this format is not supported";
                    break;
                case kFPWCSStreamStatusInfoStreamNameAlreadyInUse:
                    view.text = @"Server already has a publish stream with the same name, try using different one";
                    break;
				case kFPWCSStreamStatusInfoTranscodingRequiredButDisabled:
                    view.text = @"Transcoding required, but disabled in settings";
                    break;
                case kFPWCSStreamStatusInfoNoAvailableTranscoders:
                    view.text = @"No available transcoders for stream";
                    break;
            }
            break;
        }
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
    
    _localDisplay = [[GPUImageView alloc] initWithFrame:self.view.frame];
    _localDisplay.translatesAutoresizingMaskIntoConstraints = NO;
    _localDisplay.backgroundColor = [UIColor blackColor];
    
    #ifdef RTC_SUPPORTS_METAL
        RTCMTLVideoView *localView = [[RTCMTLVideoView alloc] init];
        localView.delegate = self;
    _localNativeDisplay = localView;
    #else
        RTCMTLVideoView *localView = [[RTCMTLVideoView alloc] init];
        localView.delegate = self;
        _localNativeDisplay = localView;
    #endif
    _localNativeDisplay.translatesAutoresizingMaskIntoConstraints = NO;
    
    #ifdef RTC_SUPPORTS_METAL
        RTCMTLVideoView *remoteView = [[RTCMTLVideoView alloc] init];
        remoteView.delegate = self;
        _remoteDisplay = remoteView;
    #else
        RTCMTLVideoView *remoteView = [[RTCMTLVideoView alloc] init];
        remoteView.delegate = self;
        _remoteDisplay = remoteView;
    #endif
    _remoteDisplay.translatesAutoresizingMaskIntoConstraints = NO;
    
    _connectUrl = [WCSViewUtil createTextField:self];
    _connectionStatus = [WCSViewUtil createLabelView];
    _connectButton = [WCSViewUtil createButton:@"CONNECT"];
    [_connectButton addTarget:self action:@selector(connectButton:) forControlEvents:UIControlEventTouchUpInside];
    
    _publishStreamLabel = [WCSViewUtil createInfoLabel:@"Publish Stream"];
    _localStreamName = [WCSViewUtil createTextField:self];
    _localStreamStatus = [WCSViewUtil createLabelView];
    _publishButton = [WCSViewUtil createButton:@"PUBLISH"];
    [_publishButton addTarget:self action:@selector(publishButton:) forControlEvents:UIControlEventTouchUpInside];
    _beautyButton = [WCSViewUtil createButton:@"Beautify Enable"];
    [_beautyButton addTarget:self action:@selector(beautify:) forControlEvents:UIControlEventTouchUpInside];
    
    _playStreamLabel = [WCSViewUtil createInfoLabel:@"Play Stream"];
    _remoteStreamName = [WCSViewUtil createTextField:self];
    _remoteStreamStatus = [WCSViewUtil createLabelView];
    _playButton = [WCSViewUtil createButton:@"PLAY"];
    [_playButton addTarget:self action:@selector(playButton:) forControlEvents:UIControlEventTouchUpInside];
    
    [self.videoContainer addSubview:_localDisplay];
    [self.videoContainer addSubview:_remoteDisplay];
    
    [self.contentView addSubview:_connectUrl];
    [self.contentView addSubview:_connectionStatus];
    [self.contentView addSubview:_connectButton];
    
    [self.contentView addSubview:_publishStreamLabel];
    [self.contentView addSubview:_localStreamName];
    [self.contentView addSubview:_localStreamStatus];
    [self.contentView addSubview:_publishButton];
    [self.contentView addSubview:_beautyButton];
    
    [self.contentView addSubview:_playStreamLabel];
    [self.contentView addSubview:_remoteStreamName];
    [self.contentView addSubview:_remoteStreamStatus];
    [self.contentView addSubview:_playButton];
    
    [self.contentView addSubview:_videoContainer];
    
    [self.scrollView addSubview:_contentView];
    [self.view addSubview:_scrollView];
    
    //set default values
    _connectUrl.text = @"wss://demo.flashphoner.com:8443/";
    _localStreamName.text = @"streamName";
    _remoteStreamName.text = @"streamName";
}

- (void)setupLayout {
    NSDictionary *views = @{
                            @"connectUrl": _connectUrl,
                            @"connectionStatus": _connectionStatus,
                            @"connectButton": _connectButton,
                            @"publishStreamLabel": _publishStreamLabel,
                            @"localStreamName": _localStreamName,
                            @"localStreamStatus": _localStreamStatus,
                            @"publishButton": _publishButton,
                            @"beautyButton": _beautyButton,
                            @"playStreamLabel": _playStreamLabel,
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
    
    _localDisplayConstraints = [[NSMutableArray alloc] init];
    _remoteDisplayConstraints = [[NSMutableArray alloc] init];
    
    //set height size
    setConstraint(_connectUrl, @"V:[connectUrl(inputFieldHeight)]", 0);
    setConstraint(_publishStreamLabel, @"V:[publishStreamLabel(labelHeight)]", 0);
    setConstraint(_playStreamLabel, @"V:[playStreamLabel(labelHeight)]", 0);
    setConstraint(_localStreamName, @"V:[localStreamName(inputFieldHeight)]", 0);
    setConstraint(_remoteStreamName, @"V:[remoteStreamName(inputFieldHeight)]", 0);
    setConstraint(_connectionStatus, @"V:[connectionStatus(statusHeight)]", 0);
    setConstraint(_localStreamStatus, @"V:[localStreamStatus(statusHeight)]", 0);
    setConstraint(_remoteStreamStatus, @"V:[remoteStreamStatus(statusHeight)]", 0);
    setConstraint(_connectButton, @"V:[connectButton(buttonHeight)]", 0);
    setConstraint(_publishButton, @"V:[publishButton(buttonHeight)]", 0);
    setConstraint(_beautyButton, @"V:[beautyButton(buttonHeight)]", 0);
    setConstraint(_playButton, @"V:[playButton(buttonHeight)]", 0);
    setConstraint(_videoContainer, @"V:[videoContainer(videoHeight)]", 0);
    
    //set width related to super view
    setConstraint(_contentView, @"H:|-hSpacing-[connectUrl]-hSpacing-|", 0);
    setConstraint(_contentView, @"H:|-hSpacing-[publishStreamLabel]-hSpacing-|", 0);
    setConstraint(_contentView, @"H:|-hSpacing-[playStreamLabel]-hSpacing-|", 0);
    setConstraint(_contentView, @"H:|-hSpacing-[localStreamName]-hSpacing-|", 0);
    setConstraint(_contentView, @"H:|-hSpacing-[remoteStreamName]-hSpacing-|", 0);
    setConstraint(_contentView, @"H:|-hSpacing-[connectionStatus]-hSpacing-|", 0);
    setConstraint(_contentView, @"H:|-hSpacing-[localStreamStatus]-hSpacing-|", 0);
    setConstraint(_contentView, @"H:|-hSpacing-[remoteStreamStatus]-hSpacing-|", 0);
    setConstraint(_contentView, @"H:|-hSpacing-[connectButton]-hSpacing-|",0);
    setConstraint(_contentView, @"H:|-hSpacing-[publishButton]-hSpacing-|", 0);
    setConstraint(_contentView, @"H:|-hSpacing-[beautyButton]-hSpacing-|", 0);
    setConstraint(_contentView, @"H:|-hSpacing-[playButton]-hSpacing-|", 0);
    setConstraint(_contentView, @"H:|-hSpacing-[videoContainer]-hSpacing-|", 0);
    
    //local display max width and height
    setConstraintWithItem(_videoContainer, _localDisplay, _videoContainer, NSLayoutAttributeHeight, NSLayoutRelationLessThanOrEqual, NSLayoutAttributeHeight, 1.0, 0);
    setConstraintWithItem(_videoContainer, _localDisplay, _videoContainer, NSLayoutAttributeWidth, NSLayoutRelationLessThanOrEqual, NSLayoutAttributeWidth, 0.48, 0);
    
    //local display aspect ratio
    NSLayoutConstraint *localARConstraint = setConstraintWithItem(_localDisplay, _localDisplay, _localDisplay, NSLayoutAttributeWidth, NSLayoutRelationEqual, NSLayoutAttributeHeight, 480.0/640.0, 0);
    [_localDisplayConstraints addObject:localARConstraint];
    
    //remote display max width and height
    setConstraintWithItem(_videoContainer, _remoteDisplay, _videoContainer, NSLayoutAttributeHeight, NSLayoutRelationLessThanOrEqual, NSLayoutAttributeHeight, 1.0, 0);
    setConstraintWithItem(_videoContainer, _remoteDisplay, _videoContainer, NSLayoutAttributeWidth, NSLayoutRelationLessThanOrEqual, NSLayoutAttributeWidth, 0.48, 0);
    
    //remote display aspect ratio
    NSLayoutConstraint *remoteARConstraint = setConstraintWithItem(_remoteDisplay, _remoteDisplay, _remoteDisplay, NSLayoutAttributeWidth, NSLayoutRelationEqual, NSLayoutAttributeHeight, 480.0/640.0, 0);
    [_remoteDisplayConstraints addObject:remoteARConstraint];
    
    //position video views inside video container
    setConstraint(_videoContainer, @"H:|[localDisplay][remoteDisplay]|", NSLayoutFormatAlignAllTop);
    setConstraint(_videoContainer, @"V:|[localDisplay]", 0);
    
    setConstraint(self.contentView, @"V:|-50-[connectUrl]-vSpacing-[connectionStatus]-vSpacing-[connectButton]-vSpacing-[publishStreamLabel]-vSpacing-[localStreamName]-vSpacing-[localStreamStatus]-vSpacing-[publishButton]-vSpacing-[beautyButton]-vSpacing-[playStreamLabel]-vSpacing-[remoteStreamName]-vSpacing-[remoteStreamStatus]-vSpacing-[playButton]-vSpacing-[videoContainer]-vSpacing-|", 0);
    
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

#pragma mark - RTCVideoViewDelegate

- (void)videoView:(id<RTCVideoRenderer>)videoView didChangeVideoSize:(CGSize)size {
    if (videoView == _remoteDisplay) {
        NSLog(@"Size of remote video %fx%f", size.width, size.height);
    } else {
        NSLog(@"Size of local video %fx%f", size.width, size.height);
    }
    if (videoView == _remoteDisplay) {
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
    } else {
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
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

@end
