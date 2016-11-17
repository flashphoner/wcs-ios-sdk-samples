

#import "WCSRemoteVideoControl.h"
#import "WCSUtil.h"

@implementation WCSRemoteVideoControlView

- (instancetype)init {
    self = [super initWithPosition:NSLayoutAttributeRight];
    if (self) {
        _scrollView = [[UIScrollView alloc] init];
        _scrollView.translatesAutoresizingMaskIntoConstraints = NO;
        _scrollView.scrollEnabled = YES;
        _contentView = [[UIView alloc] init];
        _contentView.translatesAutoresizingMaskIntoConstraints = NO;
        _hideButton = [WCSViewUtil createButton:@"Hide"];
        [_hideButton addTarget:self action:@selector(onHideButton:) forControlEvents:UIControlEventTouchUpInside];
        _playVideo = [[WCSSwitchView alloc] initWithLabelText:@"Play Video"];
        [_playVideo.control addTarget:self action:@selector(controlValueChanged:) forControlEvents:UIControlEventValueChanged];
        [_playVideo.control setOn:YES];
        _videoResolution = [[WCSVideoResolutionInputWithDefaultView alloc] initWithLabelText:@"Size"];
        [_videoResolution.control addTarget:self action:@selector(controlValueChanged:) forControlEvents:UIControlEventValueChanged];
        [_videoResolution.control setOn:NO];
        [self controlValueChanged:_videoResolution.control];
        _bitrate = [[WCSTextInputWithDefaultView alloc] initWithLabelText:@"Bitrate"];
        [_bitrate.control addTarget:self action:@selector(controlValueChanged:) forControlEvents:UIControlEventValueChanged];
        [_bitrate.control setOn:NO];
        [self controlValueChanged:_bitrate.control];
        _quality = [[WCSTextInputWithDefaultView alloc] initWithLabelText:@"Quality"];
        [_quality.control addTarget:self action:@selector(controlValueChanged:) forControlEvents:UIControlEventValueChanged];
        [_quality.control setOn:NO];
        [self controlValueChanged:_quality.control];
        [_contentView addSubview:_playVideo];
        [_contentView addSubview:_videoResolution];
        [_contentView addSubview:_bitrate];
        [_contentView addSubview:_quality];
        [_scrollView addSubview:_contentView];
        [self addSubview:_hideButton];
        [self addSubview:_scrollView];
        
        NSDictionary *views = @{
                                @"hideButton": _hideButton,
                                @"playVideo": _playVideo,
                                @"videoResolution": _videoResolution,
                                @"bitrate": _bitrate,
                                @"quality": _quality,
                                @"content": _contentView,
                                @"scroll": _scrollView,
                                @"container": self
                                };
        NSDictionary *metrics = @{
                                  @"height": @30,
                                  @"vSpacing": @10,
                                  @"hSpacing": @10
                                  };
        [_contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[playVideo]|" options:0 metrics:metrics views:views]];
        [_contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[videoResolution]|" options:0 metrics:metrics views:views]];
        [_contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[bitrate]|" options:0 metrics:metrics views:views]];
        [_contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[quality]|" options:0 metrics:metrics views:views]];
        
        [_contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-vSpacing-[playVideo]-vSpacing-[videoResolution]-vSpacing-[bitrate]-vSpacing-[quality]-vSpacing-|" options:0 metrics:metrics views:views]];

        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-hSpacing-[hideButton]-hSpacing-|" options:0 metrics:metrics views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[scroll]|" options:0 metrics:metrics views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-hSpacing-[content]-hSpacing-|" options:0 metrics:metrics views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-vSpacing-[hideButton][scroll]|" options:0 metrics:metrics views:views]];
        [_scrollView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[content]|" options:0 metrics:metrics views:views]];
        [self addConstraint:[NSLayoutConstraint constraintWithItem:_contentView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeWidth multiplier:1 constant:-20]];
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
    } else if (sender == _videoResolution.control) {
        if (_videoResolution.control.isOn) {
            _videoResolution.width.userInteractionEnabled = YES;
            _videoResolution.height.userInteractionEnabled = YES;
        } else {
            _videoResolution.width.userInteractionEnabled = NO;
            _videoResolution.height.userInteractionEnabled = NO;
            _videoResolution.width.text = @"0";
            _videoResolution.height.text = @"0";
        }
    } else if (sender == _bitrate.control) {
        if (_bitrate.control.isOn) {
            _bitrate.input.userInteractionEnabled = YES;
        } else {
            _bitrate.input.userInteractionEnabled = NO;
            _bitrate.input.text = @"0";
        }
    } else if (sender == _quality.control) {
        if (_quality.control.isOn) {
            _quality.input.userInteractionEnabled = YES;
        } else {
            _quality.input.userInteractionEnabled = NO;
            _quality.input.text = @"0";
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