

#import "WCSRemoteVideoControl.h"
#import "WCSUtil.h"

@implementation WCSRemoteVideoControlView

- (instancetype)init {
    self = [super initWithPosition:NSLayoutAttributeRight];
    if (self) {
        _hideButton = [WCSViewUtil createButton:@"Hide"];
        [_hideButton addTarget:self action:@selector(onHideButton:) forControlEvents:UIControlEventTouchUpInside];
        _playVideo = [[WCSSwitchView alloc] initWithLabelText:@"Play Video"];
        [_playVideo.control addTarget:self action:@selector(controlValueChanged:) forControlEvents:UIControlEventValueChanged];
        [_playVideo.control setOn:YES];
        _videoResolution = [[WCSVideoResolutionInputWithDefaultView alloc] initWithLabelText:@"Size"];
        _bitrate = [[WCSTextInputWithDefaultView alloc] initWithLabelText:@"Bitrate"];
        _quality = [[WCSTextInputWithDefaultView alloc] initWithLabelText:@"Quality"];
        [self addSubview:_hideButton];
        [self addSubview:_playVideo];
        [self addSubview:_videoResolution];
        [self addSubview:_bitrate];
        [self addSubview:_quality];
        
        NSDictionary *views = @{
                                @"hideButton": _hideButton,
                                @"playVideo": _playVideo,
                                @"videoResolution": _videoResolution,
                                @"bitrate": _bitrate,
                                @"quality": _quality,
                                @"container": self
                                };
        NSDictionary *metrics = @{
                                  @"height": @30,
                                  @"vSpacing": @10,
                                  @"hSpacing": @20
                                  };
        
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-hSpacing-[hideButton]-hSpacing-|" options:0 metrics:metrics views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-hSpacing-[playVideo]-hSpacing-|" options:0 metrics:metrics views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-hSpacing-[videoResolution]-hSpacing-|" options:0 metrics:metrics views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-hSpacing-[bitrate]-hSpacing-|" options:0 metrics:metrics views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-hSpacing-[quality]-hSpacing-|" options:0 metrics:metrics views:views]];
        
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-vSpacing-[hideButton]-vSpacing-[playVideo]-vSpacing-[videoResolution]-vSpacing-[bitrate]-vSpacing-[quality]" options:0 metrics:metrics views:views]];
    }
    return self;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

- (void)onHideButton:(UIButton *)button {
    [_videoResolution.width resignFirstResponder];
    [_videoResolution.height resignFirstResponder];
    [_bitrate.input resignFirstResponder];
    [_quality.input resignFirstResponder];
    [self hide];
}

- (void)controlValueChanged:(id)sender {
    if (sender == _playVideo.control) {
        if (_playVideo.control.isOn) {
            [self muteVideoInputs:NO];
        } else {
            [self muteVideoInputs:YES];
        }
    }
}

- (void)muteVideoInputs:(BOOL)mute {
    BOOL enabled = !mute;
    _videoResolution.userInteractionEnabled = enabled;
    _bitrate.userInteractionEnabled = enabled;
    _quality.userInteractionEnabled = enabled;
}

- (FPWCSApi2MediaConstraints *)toMediaConstraints {
    FPWCSApi2MediaConstraints *ret = [[FPWCSApi2MediaConstraints alloc] init];
    ret.audio = YES;
    if ([_playVideo.control isOn]) {
        FPWCSApi2VideoConstraints *video = [[FPWCSApi2VideoConstraints alloc] init];
        video.minWidth = video.maxWidth = [_videoResolution.width.text integerValue];
        video.minHeight = video.maxHeight = [_videoResolution.height.text integerValue];
        video.bitrate = [_bitrate.input.text integerValue];
        video.quality = [_quality.input.text integerValue];
        ret.video = video;
    }
    return ret;
}


@end