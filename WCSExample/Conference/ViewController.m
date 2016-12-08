//
//  ViewController.m
//  WCSApiExample
//
//  Created by user on 24/11/2015.
//  Copyright © 2015 user. All rights reserved.
//

#import "ViewController.h"
#import "WCSUtil.h"
#import <AVFoundation/AVFoundation.h>
#import <FPWCSApi2/FPWCSApi2.h>

@interface ParticipantView : NSObject
@property RTCEAGLVideoView *display;
@property UILabel *login;
@end
@implementation ParticipantView
@end


@implementation ViewController

FPWCSApi2RoomManager *roomManager;
FPWCSApi2Room *room;
FPWCSApi2Stream *player1Stream;
FPWCSApi2Stream *player2Stream;
FPWCSApi2Stream *publishStream;
WCSStack *freeViews;
NSMutableDictionary *busyViews;

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupViews];
    [self setupLayout];
    freeViews = [[WCSStack alloc] init];
    ParticipantView *pv1 = [[ParticipantView alloc] init];
    pv1.display = _player1Display;
    pv1.login = _player1Login;
    [freeViews push:pv1];
    ParticipantView *pv2 = [[ParticipantView alloc] init];
    pv2.display = _player2Display;
    pv2.login = _player2Login;
    [freeViews push:pv2];
    busyViews = [[NSMutableDictionary alloc] init];
    
    [self onUnpublished];
    [self onLeaved];
    [self onDisconnected];
    NSLog(@"Did load views");
}

//connect
- (void)connect {
    FPWCSApi2RoomManagerOptions *options = [[FPWCSApi2RoomManagerOptions alloc] init];
    options.urlServer = _connectUrl.text;
    options.username = _connectLogin.input.text;
    NSError *error;
    roomManager = [FPWCSApi2 createRoomManager:options error:&error];
    if (!roomManager) {
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
    }
    
    [roomManager on:kFPWCSRoomManagerEventConnected callback:^(FPWCSApi2RoomManager *rManager){
        [self changeConnectionStatus:kFPWCSRoomManagerEventConnected];
        [self onConnected:rManager];
    }];
    
    [roomManager on:kFPWCSRoomManagerEventDisconnected callback:^(FPWCSApi2RoomManager *rManager){
        [self changeConnectionStatus:kFPWCSRoomManagerEventDisconnected];
        [self onUnpublished];
        [self onLeaved];
        [self onDisconnected];
    }];
}

//session and stream status handlers
- (void)onConnected:(FPWCSApi2RoomManager *)roomManager {
    [_connectButton setTitle:@"DISCONNECT" forState:UIControlStateNormal];
    [self changeViewState:_connectButton enabled:YES];
    [self changeViewState:_joinButton enabled:YES];
}

- (void)onUnpublished {
    publishStream = nil;
    [self changeViewState:_publishButton enabled:YES];
    [_publishButton setTitle:@"PUBLISH" forState:UIControlStateNormal];
    [self changeViewState:_muteAudio enabled:NO];
    [self changeViewState:_muteVideo enabled:NO];
}

- (void)onLeaved {
    _joinStatus.text = @"NO STATUS";
    [self changeViewState:_joinButton enabled:YES];
    [_joinButton setTitle:@"JOIN" forState:UIControlStateNormal];
    [self changeViewState:_publishButton enabled:NO];
    [self changeViewState:_sendButton enabled:NO];
    NSArray *allKeys = [busyViews allKeys];
    for (NSString *key in allKeys) {
        ParticipantView *pv = [busyViews valueForKey:key];
        [busyViews removeObjectForKey:pv.login.text];
        [freeViews push:pv];
        pv.login.text = @"NONE";
    }
}

- (void)onDisconnected {
    [_connectButton setTitle:@"CONNECT" forState:UIControlStateNormal];
    [self changeViewState:_connectButton enabled:YES];
    [self changeViewState:_connectUrl enabled:YES];
    [self changeViewState:_connectLogin.input enabled:YES];
    [self changeViewState:_joinButton enabled:NO];
}

//user interface handlers

- (void)connectButton:(UIButton *)button {
    [self changeViewState:button enabled:NO];
    if ([button.titleLabel.text isEqualToString:@"DISCONNECT"]) {
        if (roomManager) {
            [roomManager disconnect];
        }
    } else {
        //todo check url is not empty
        [self changeViewState:_connectUrl enabled:NO];
        [self changeViewState:_connectLogin.input enabled:NO];
        [self connect];
    }
}

- (void) joinButton:(UIButton *) button {
    [self changeViewState:button enabled:NO];
    if ([button.titleLabel.text isEqualToString:@"LEAVE"]) {
        if (room) {
            [room leave];
        }
        [self onUnpublished];
        [self onLeaved];
    } else {
        FPWCSApi2RoomOptions * options = [[FPWCSApi2RoomOptions alloc] init];
        options.name = _joinRoomName.input.text;
        room = [roomManager join:options];
        
        [room onStateCallback:^(FPWCSApi2Room *room) {
            NSDictionary *participants = [room getParticipants];
            if ([participants count] >= 3) {
                [room leave];
                _joinStatus.text = @"Room is full";
                [self changeViewState:_joinButton enabled:YES];
                return;
                
            }
            NSString *chatState = @"participants: ";
            for (NSString* key in participants) {
                FPWCSApi2RoomParticipant *participant = [participants valueForKey:key];
                ParticipantView *pv = [freeViews pop];
                [busyViews setValue:pv forKey:[participant getName]];
                [participant play:pv.display];
                pv.login.text = [participant getName];
                chatState = [NSString stringWithFormat:@"%@%@, ", chatState, [participant getName]];
            }
            _joinStatus.text = @"JOINED";
            [self changeViewState:_joinButton enabled:YES];
            [_joinButton setTitle:@"LEAVE" forState:UIControlStateNormal];
            [self changeViewState:_publishButton enabled:YES];
            [self changeViewState:_sendButton enabled:YES];
            if ([participants count] == 0) {
                _messageHistory.text = [NSString stringWithFormat:@"%@\n%@ - %@", _messageHistory.text, @"chat", @"room is empty"];
            } else {
                _messageHistory.text = [NSString stringWithFormat:@"%@\n%@ - %@", _messageHistory.text, @"chat", [chatState substringToIndex:MAX((int)[chatState length]-2, 0)]];
            }
        }];
        
        [room on:kFPWCSRoomParticipantEventJoined participantCallback:^(FPWCSApi2Room *room, FPWCSApi2RoomParticipant *participant) {
            ParticipantView *pv = [freeViews pop];
            if (pv) {
                pv.login.text = [participant getName];
                _messageHistory.text = [NSString stringWithFormat:@"%@\n%@ - %@", _messageHistory.text, participant.getName, @"joined"];
                [busyViews setValue:pv forKey:[participant getName]];
            }
        }];
        
        [room on:kFPWCSRoomParticipantEventPublished participantCallback:^(FPWCSApi2Room *room, FPWCSApi2RoomParticipant *participant) {
            ParticipantView *pv = [busyViews valueForKey:[participant getName]];
            if (pv) {
                [participant play:pv.display];
            }
        }];
        
        [room on:kFPWCSRoomParticipantEventLeft participantCallback:^(FPWCSApi2Room *room, FPWCSApi2RoomParticipant *participant) {
            ParticipantView *pv = [busyViews valueForKey:[participant getName]];
            if (pv) {
                pv.login.text = @"NONE";
                _messageHistory.text = [NSString stringWithFormat:@"%@\n%@ - %@", _messageHistory.text, participant.getName, @"left"];
                [busyViews removeObjectForKey:[participant getName]];
                [freeViews push:pv];
            }
        }];
        
        [room onMessageCallback:^(FPWCSApi2Room *room, FPWCSApi2RoomMessage *message) {
            _messageHistory.text = [NSString stringWithFormat:@"%@\n%@ - %@", _messageHistory.text, message.from, message.text];
        }];
    }
}

- (void)muteAudioChanged:(id)sender {
    if (publishStream) {
        if (_muteAudio.control.isOn) {
            [publishStream muteAudio];
        } else {
            [publishStream unmuteAudio];
        }
    }
}

- (void)muteVideoChanged:(id)sender {
    if (publishStream) {
        if (_muteVideo.control.isOn) {
            [publishStream muteVideo];
        } else {
            [publishStream unmuteVideo];
        }
    }
}

- (void)publishButton:(UIButton *)button {
    [self changeViewState:button enabled:NO];
    if ([button.titleLabel.text isEqualToString:@"STOP"]) {
        [room unpublish];
    } else {
        publishStream = [room publish:_localDisplay];
        [publishStream on:kFPWCSStreamStatusPublishing callback:^(FPWCSApi2Stream *rStream){
            [self changeViewState:_publishButton enabled:YES];
            [self changeLocalStatus:rStream];
            [_publishButton setTitle:@"STOP" forState:UIControlStateNormal];
            [self changeViewState:_muteAudio enabled:YES];
            [self changeViewState:_muteVideo enabled:YES];
        }];
        
        [publishStream on:kFPWCSStreamStatusUnpublished callback:^(FPWCSApi2Stream *rStream){
            [self onUnpublished];
            [self changeLocalStatus:rStream];
        }];
        
        [publishStream on:kFPWCSStreamStatusFailed callback:^(FPWCSApi2Stream *rStream){
            [self onUnpublished];
            [self changeLocalStatus:rStream];
    
        }];

    }
}

- (void)sendButton:(UIButton *)button {
    for (NSString *name in [room getParticipants]) {
        FPWCSApi2RoomParticipant *participant = [room getParticipants][name];
        [participant sendMessage:_messageBody.text];
    }
    _messageHistory.text = [NSString stringWithFormat:@"%@\n%@ - %@", _messageHistory.text, _connectLogin.input.text, _messageBody.text];
    _messageBody.text = @"";
}

//status handlers
- (void)changeConnectionStatus:(kFPWCSRoomManagerEvent)event {
    _connectionStatus.text = [FPWCSApi2RoomManager roomManagerEventToString:event];
    switch (event) {
        case kFPWCSRoomManagerEventDisconnected:
            _connectionStatus.textColor = [UIColor redColor];
            break;
        case kFPWCSRoomManagerEventConnected:
            _connectionStatus.textColor = [UIColor greenColor];
            break;
        default:
            _connectionStatus.textColor = [UIColor darkTextColor];
            break;
    }
}

- (void)changeLocalStatus:(FPWCSApi2Stream *)stream {
    _localStatus.text = [FPWCSApi2Model streamStatusToString:[stream getStatus]];
    switch ([stream getStatus]) {
        case kFPWCSStreamStatusFailed:
            _localStatus.textColor = [UIColor redColor];
            break;
        case kFPWCSStreamStatusPlaying:
        case kFPWCSStreamStatusPublishing:
            _localStatus.textColor = [UIColor greenColor];
            break;
        default:
            _localStatus.textColor = [UIColor darkTextColor];
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
    _connectUrl.translatesAutoresizingMaskIntoConstraints = NO;
    _connectLogin = [[WCSTextInputView alloc] initWithLabelText:@"Login"];
    _connectLogin.input.text = @"testLogin";
    _connectLogin.translatesAutoresizingMaskIntoConstraints = NO;
    _connectionStatus = [WCSViewUtil createLabelView];
    _connectionStatus.translatesAutoresizingMaskIntoConstraints = NO;
    _connectButton = [WCSViewUtil createButton:@"CONNECT"];
    [_connectButton addTarget:self action:@selector(connectButton:) forControlEvents:UIControlEventTouchUpInside];
    _connectButton.translatesAutoresizingMaskIntoConstraints = NO;
    
    _joinRoomName = [[WCSTextInputView alloc] initWithLabelText:@"Room"];
    _joinRoomName.input.text = @"testRoom";
    _joinRoomName.translatesAutoresizingMaskIntoConstraints = NO;
    _joinStatus = [WCSViewUtil createLabelView];
    _joinStatus.translatesAutoresizingMaskIntoConstraints = NO;
    _joinButton = [WCSViewUtil createButton:@"JOIN"];
    [_joinButton addTarget:self action:@selector(joinButton:) forControlEvents:UIControlEventTouchUpInside];
    _joinButton.translatesAutoresizingMaskIntoConstraints = NO;
    
    _player1Container = [[UIView alloc] init];
    _player1Container.translatesAutoresizingMaskIntoConstraints = NO;
    _player1Display = [[RTCEAGLVideoView alloc] init];
    _player1Display.delegate = self;
    _player1Display.translatesAutoresizingMaskIntoConstraints = NO;
    _player1Login = [WCSViewUtil createLabelView];
    _player1Login.translatesAutoresizingMaskIntoConstraints = NO;
    _player1Login.text = @"NONE";
    
    _player2Container = [[UIView alloc] init];
    _player2Container.translatesAutoresizingMaskIntoConstraints = NO;
    _player2Display = [[RTCEAGLVideoView alloc] init];
    _player2Display.delegate = self;
    _player2Display.translatesAutoresizingMaskIntoConstraints = NO;
    _player2Login = [WCSViewUtil createLabelView];
    _player2Login.translatesAutoresizingMaskIntoConstraints = NO;
    _player2Login.text = @"NONE";
    
    _localVideoContainer = [[UIView alloc] init];
    _localVideoContainer.translatesAutoresizingMaskIntoConstraints = NO;
    _localDisplay = [[RTCEAGLVideoView alloc] init];
    _localDisplay.delegate = self;
    _localDisplay.translatesAutoresizingMaskIntoConstraints = NO;
    _localStatus = [WCSViewUtil createLabelView];
    _localStatus.translatesAutoresizingMaskIntoConstraints = NO;
    _muteAudio = [[WCSSwitchView alloc] initWithLabelText:@"Mute Audio"];
    _muteAudio.translatesAutoresizingMaskIntoConstraints = NO;
    [_muteAudio.control addTarget:self action:@selector(muteAudioChanged:) forControlEvents:UIControlEventValueChanged];
    _muteVideo = [[WCSSwitchView alloc] initWithLabelText:@"Mute Audio"];
    _muteVideo.translatesAutoresizingMaskIntoConstraints = NO;
    [_muteVideo.control addTarget:self action:@selector(muteVideoChanged:) forControlEvents:UIControlEventValueChanged];
    _publishButton = [WCSViewUtil createButton:@"PUBLISH"];
    _publishButton.translatesAutoresizingMaskIntoConstraints = NO;
    [_publishButton addTarget:self action:@selector(publishButton:) forControlEvents:UIControlEventTouchUpInside];
    
    _messageHistory = [[UITextView alloc] init];
    _messageHistory.translatesAutoresizingMaskIntoConstraints = NO;
    _messageBody = [WCSViewUtil createTextField:self];
    _messageBody.translatesAutoresizingMaskIntoConstraints = NO;
    _sendButton = [WCSViewUtil createButton:@"SEND"];
    _sendButton.translatesAutoresizingMaskIntoConstraints = NO;
    [_sendButton addTarget:self action:@selector(sendButton:) forControlEvents:UIControlEventTouchUpInside];

    [self.contentView addSubview:_connectUrl];
    [self.contentView addSubview:_connectLogin];
    [self.contentView addSubview:_connectionStatus];
    [self.contentView addSubview:_connectButton];
    
    [self.contentView addSubview:_joinRoomName];
    [self.contentView addSubview:_joinStatus];
    [self.contentView addSubview:_joinButton];
    
    [self.player1Container addSubview:_player1Display];
    [self.player1Container addSubview:_player1Login];
    [self.contentView addSubview:_player1Container];
    
    [self.player2Container addSubview:_player2Display];
    [self.player2Container addSubview:_player2Login];
    [self.contentView addSubview:_player2Container];
    
    [self.localVideoContainer addSubview:_localDisplay];
    [self.contentView addSubview:_localVideoContainer];
    [self.contentView addSubview:_localStatus];
    [self.contentView addSubview:_muteAudio];
    [self.contentView addSubview:_muteVideo];
    [self.contentView addSubview:_publishButton];
    
    [self.contentView addSubview:_messageHistory];
    [self.contentView addSubview:_messageBody];
    [self.contentView addSubview:_sendButton];
    
    [self.scrollView addSubview:_contentView];
    [self.view addSubview:_scrollView];
    
    //set default values
    _connectUrl.text = @"wss://wcs5-eu.flashphoner.com:8443/";
}

- (void)setupLayout {
    NSDictionary *views = @{
                            @"connectUrl": _connectUrl,
                            @"connectLogin": _connectLogin,
                            @"connectionStatus": _connectionStatus,
                            @"connectButton": _connectButton,
                            @"joinRoomName": _joinRoomName,
                            @"joinStatus": _joinStatus,
                            @"joinButton": _joinButton,
                            @"player1Container": _player1Container,
                            @"player1Display": _player1Display,
                            @"player1Login": _player1Login,
                            @"player2Container": _player2Container,
                            @"player2Display": _player2Display,
                            @"player2Login": _player2Login,
                            @"localVideoContainer": _localVideoContainer,
                            @"localDisplay": _localDisplay,
                            @"localStatus": _localStatus,
                            @"muteAudio":_muteAudio,
                            @"muteVideo":_muteVideo,
                            @"publishButton": _publishButton,
                            @"messageHistory": _messageHistory,
                            @"messageBody":_messageBody,
                            @"sendButton":_sendButton,
                            @"contentView": _contentView,
                            @"scrollView": _scrollView
                            };
    
    NSNumber *videoHeight = @120;
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
                              @"smallVideoHeight": videoHeight,
                              @"videoHeight": [NSNumber numberWithInt:[videoHeight intValue] * 2],
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
    setConstraint(_joinStatus, @"V:[joinStatus(statusHeight)]", 0);
    setConstraint(_joinButton, @"V:[joinButton(buttonHeight)]", 0);
    setConstraint(_player1Display, @"V:[player1Display(smallVideoHeight)]", 0);
    setConstraint(_player1Login, @"V:[player1Login(buttonHeight)]", 0);
    setConstraint(_player2Display, @"V:[player2Display(smallVideoHeight)]", 0);
    setConstraint(_player2Login, @"V:[player2Login(statusHeight)]", 0);
    setConstraint(_localDisplay, @"V:[localDisplay(videoHeight)]", 0);
    setConstraint(_localStatus, @"V:[localStatus(statusHeight)]", 0);
    setConstraint(_muteAudio, @"V:[muteAudio(statusHeight)]", 0);
    setConstraint(_muteVideo, @"V:[muteVideo(statusHeight)]", 0);
    setConstraint(_publishButton, @"V:[publishButton(buttonHeight)]", 0);
    setConstraint(_messageHistory, @"V:[messageHistory(150)]", 0);
    setConstraint(_messageBody, @"V:[messageBody(inputFieldHeight)]", 0);
    setConstraint(_sendButton, @"V:[sendButton(buttonHeight)]", 0);
    
    //set width related to super view
    setConstraint(_player1Container, @"H:|-hSpacing-[player1Display]-hSpacing-|", 0);
    setConstraint(_player1Container, @"H:|-hSpacing-[player1Login]-hSpacing-|", 0);
    setConstraintWithItem(_contentView, _player1Container, _contentView, NSLayoutAttributeHeight, NSLayoutRelationLessThanOrEqual, NSLayoutAttributeHeight, 1.0, 0);
    setConstraintWithItem(_contentView, _player1Container, _contentView, NSLayoutAttributeWidth, NSLayoutRelationLessThanOrEqual, NSLayoutAttributeWidth, 0.48, 0);
    setConstraint(_player1Container, @"V:|-vSpacing-[player1Display]-vSpacing-[player1Login]-vSpacing-|", 0);

    
    setConstraint(_player2Container, @"H:|-hSpacing-[player2Display]-hSpacing-|", 0);
    setConstraint(_player2Container, @"H:|-hSpacing-[player2Login]-hSpacing-|", 0);
    setConstraintWithItem(_contentView, _player2Container, _contentView, NSLayoutAttributeHeight, NSLayoutRelationLessThanOrEqual, NSLayoutAttributeHeight, 1.0, 0);
    setConstraintWithItem(_contentView, _player2Container, _contentView, NSLayoutAttributeWidth, NSLayoutRelationLessThanOrEqual, NSLayoutAttributeWidth, 0.48, 0);
    setConstraint(_player2Container, @"V:|-vSpacing-[player2Display]-vSpacing-[player2Login]-vSpacing-|", 0);
    
    setConstraint(_contentView, @"H:|-hSpacing-[connectUrl]-hSpacing-|", 0);
    setConstraint(_contentView, @"H:|-hSpacing-[connectionStatus]-hSpacing-|", 0);
    setConstraint(_contentView, @"H:|-hSpacing-[connectLogin]-hSpacing-|", 0);
    setConstraint(_contentView, @"H:|-hSpacing-[connectButton]-hSpacing-|",0);
    setConstraint(_contentView, @"H:|-hSpacing-[joinRoomName]-hSpacing-|", 0);
    setConstraint(_contentView, @"H:|-hSpacing-[joinStatus]-hSpacing-|", 0);
    setConstraint(_contentView, @"H:|-hSpacing-[joinButton]-hSpacing-|", 0);
    setConstraint(_contentView, @"H:|[player1Container][player2Container]|", NSLayoutFormatAlignAllTop);
    setConstraint(_contentView, @"H:|-hSpacing-[localVideoContainer]-hSpacing-|", 0);
    setConstraint(_contentView, @"H:|-hSpacing-[localStatus]-hSpacing-|", 0);
    setConstraint(_contentView, @"H:|-hSpacing-[muteAudio]-hSpacing-|", 0);
    setConstraint(_contentView, @"H:|-hSpacing-[muteVideo]-hSpacing-|", 0);
    setConstraint(_contentView, @"H:|-hSpacing-[publishButton]-hSpacing-|", 0);
    setConstraint(_contentView, @"H:|-hSpacing-[messageHistory]-hSpacing-|", 0);
    setConstraint(_contentView, @"H:|-hSpacing-[messageBody]-hSpacing-|", 0);
    setConstraint(_contentView, @"H:|-hSpacing-[sendButton]-hSpacing-|", 0);
    
    //remote display max width and height
    setConstraintWithItem(_localVideoContainer, _localDisplay, _localVideoContainer, NSLayoutAttributeHeight, NSLayoutRelationLessThanOrEqual, NSLayoutAttributeHeight, 1.0, 0);
    setConstraintWithItem(_localVideoContainer, _localDisplay, _localVideoContainer, NSLayoutAttributeWidth, NSLayoutRelationLessThanOrEqual, NSLayoutAttributeWidth, 1.0, 0);
    
    _localDisplayConstraints = [[NSMutableArray alloc] init];
    [_localDisplayConstraints addObject:setConstraintWithItem(_localDisplay, _localDisplay, _localDisplay, NSLayoutAttributeWidth, NSLayoutRelationEqual, NSLayoutAttributeHeight, 640.0/480.0, 0)];
    
    //position video views inside video container
    setConstraint(_localVideoContainer, @"H:|[localDisplay]|", NSLayoutFormatAlignAllTop);
    setConstraint(_localVideoContainer, @"V:|[localDisplay]|", 0);

    setConstraint(_contentView, @"V:|-50-[connectUrl]-vSpacing-[connectLogin]-vSpacing-[connectionStatus]-vSpacing-[connectButton]-vSpacing-[joinRoomName]-vSpacing-[joinStatus]-vSpacing-[joinButton]-vSpacing-[player1Container]-vSpacing-[localVideoContainer]-vSpacing-[localStatus]-vSpacing-[muteAudio]-vSpacing-[muteVideo]-vSpacing-[publishButton]-vSpacing-[messageHistory]-vSpacing-[messageBody]-vSpacing-[sendButton]-vSpacing-|", 0);
    
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
    [_player1DisplayConstraints addObject:setConstraintWithItem(_player1Display, _player1Display, _player1Display, NSLayoutAttributeWidth, NSLayoutRelationEqual, NSLayoutAttributeHeight, 640.0/480.0, 0)];
    
    //player2 display aspect ratio
    [_player2DisplayConstraints addObject:setConstraintWithItem(_player2Display, _player2Display, _player2Display, NSLayoutAttributeWidth, NSLayoutRelationEqual, NSLayoutAttributeHeight, 640.0/480.0, 0)];

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - RTCEAGLVideoViewDelegate

- (void)videoView:(RTCEAGLVideoView*)videoView didChangeVideoSize:(CGSize)size {
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
    } else if (videoView == _player2Display) {
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
    } else if (videoView == _localDisplay) {
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
