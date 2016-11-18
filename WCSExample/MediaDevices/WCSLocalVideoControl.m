
#import "WCSLocalVideoControl.h"
#import "WCSUtil.h"

@implementation WCSLocalVideoControlView {
    FPWCSApi2MediaDeviceList *localDevices;
}

- (instancetype)init {
    self = [super initWithPosition:NSLayoutAttributeLeft];
    if (self) {
        localDevices = [FPWCSApi2 getMediaDevices];
        _scrollView = [[UIScrollView alloc] init];
        _scrollView.translatesAutoresizingMaskIntoConstraints = NO;
        _scrollView.scrollEnabled = YES;
        _contentView = [[UIView alloc] init];
        _contentView.translatesAutoresizingMaskIntoConstraints = NO;
        _hideButton = [WCSViewUtil createButton:@"Hide"];
        [_hideButton addTarget:self action:@selector(onHideButton:) forControlEvents:UIControlEventTouchUpInside];
        _sendAudio = [[WCSSwitchView alloc] initWithLabelText:@"Send Audio"];
        [_sendAudio.control addTarget:self action:@selector(controlValueChanged:) forControlEvents:UIControlEventValueChanged];
        [_sendAudio.control setOn:YES];
        _micSelector = [[WCSPickerInputView alloc] initWithLabelText:@"Mic" pickerDelegate:self];
        //set default mic
        if (localDevices.audio.count > 0) {
            _micSelector.input.text = ((FPWCSApi2MediaDevice *)(localDevices.audio[0])).label;
        }
        _muteAudio = [[WCSSwitchView alloc] initWithLabelText:@"Mute Audio"];
        
        _border = [WCSViewUtil createBorder:@3];
        
        _sendVideo = [[WCSSwitchView alloc] initWithLabelText:@"Send Video"];
        [_sendVideo.control addTarget:self action:@selector(controlValueChanged:) forControlEvents:UIControlEventValueChanged];
        [_sendVideo.control setOn:YES];
        _camSelector = [[WCSPickerInputView alloc] initWithLabelText:@"Cam" pickerDelegate:self];
        //set default cam
        if (localDevices.video.count > 0) {
            _camSelector.input.text = ((FPWCSApi2MediaDevice *)(localDevices.video[0])).label;
        }
        _videoResolution = [[WCSVideoResolutionInputView alloc] initWithLabelText:@"Size"];
        _videoResolution.width.text = @"640";
        _videoResolution.height.text = @"480";
        _fpsSelector = [[WCSPickerInputView alloc] initWithLabelText:@"FPS" pickerDelegate:self];
        //set default fps
        _fpsSelector.input.text = @"30";
        [_fpsSelector.picker selectRow:[_fpsSelector.picker numberOfRowsInComponent:0] - 1 inComponent:0 animated:NO];
        _bitrate = [[WCSTextInputView alloc] initWithLabelText:@"Bitrate"];
        _quality = [[WCSTextInputView alloc] initWithLabelText:@"Quality"];
        _muteVideo = [[WCSSwitchView alloc] initWithLabelText:@"Mute Video"];
        [_contentView addSubview:_sendAudio];
        [_contentView addSubview:_micSelector];
        [_contentView addSubview:_muteAudio];
        [_contentView addSubview:_border];
        [_contentView addSubview:_sendVideo];
        [_contentView addSubview:_camSelector];
        [_contentView addSubview:_videoResolution];
        [_contentView addSubview:_fpsSelector];
        [_contentView addSubview:_bitrate];
        [_contentView addSubview:_quality];
        [_contentView addSubview:_muteVideo];
        [_scrollView addSubview:_contentView];
        [self addSubview:_hideButton];
        [self addSubview:_scrollView];
        
        NSDictionary *views = @{
                                @"hideButton": _hideButton,
                                @"sendAudio": _sendAudio,
                                @"micSelector": _micSelector,
                                @"muteAudio": _muteAudio,
                                @"border": _border,
                                @"sendVideo": _sendVideo,
                                @"camSelector": _camSelector,
                                @"videoResolution": _videoResolution,
                                @"fpsSelector": _fpsSelector,
                                @"bitrate": _bitrate,
                                @"quality": _quality,
                                @"muteVideo": _muteVideo,
                                @"content": _contentView,
                                @"scroll": _scrollView,
                                @"container": self
                                };
        NSDictionary *metrics = @{
                                  @"height": @30,
                                  @"vSpacing": @10,
                                  @"hSpacing": @10
                                  };
        [_contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[sendAudio]|" options:0 metrics:metrics views:views]];
        [_contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[micSelector]|" options:0 metrics:metrics views:views]];
        [_contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[muteAudio]|" options:0 metrics:metrics views:views]];
        [_contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[border]|" options:0 metrics:metrics views:views]];
        [_contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[sendVideo]|" options:0 metrics:metrics views:views]];
        [_contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[camSelector]|" options:0 metrics:metrics views:views]];
        [_contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[videoResolution]|" options:0 metrics:metrics views:views]];
        [_contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[fpsSelector]|" options:0 metrics:metrics views:views]];
        [_contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[bitrate]|" options:0 metrics:metrics views:views]];
        [_contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[quality]|" options:0 metrics:metrics views:views]];
        [_contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[muteVideo]|" options:0 metrics:metrics views:views]];
        
        [_contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-vSpacing-[sendAudio]-vSpacing-[micSelector]-vSpacing-[muteAudio]-vSpacing-[border]-vSpacing-[sendVideo]-vSpacing-[camSelector]-vSpacing-[videoResolution]-vSpacing-[fpsSelector]-vSpacing-[bitrate]-vSpacing-[quality]-vSpacing-[muteVideo]-vSpacing-|" options:0 metrics:metrics views:views]];
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

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    FPWCSApi2MediaDevice *device;
    if (pickerView == _micSelector.picker) {
        device = localDevices.audio[row];
        _micSelector.input.text = device.label;
        [_micSelector.input resignFirstResponder];
    } else if (pickerView == _camSelector.picker) {
        device = localDevices.video[row];
        _camSelector.input.text = device.label;
        [_camSelector.input resignFirstResponder];
    } else if (pickerView == _fpsSelector.picker) {
        _fpsSelector.input.text = [NSString stringWithFormat:@"%d", (int)(row + 5)];
        [_fpsSelector.input resignFirstResponder];
    }
}

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    if (pickerView == _micSelector.picker) {
        return localDevices.audio.count;
    } else if (pickerView == _camSelector.picker) {
        return localDevices.video.count;
    } else if (pickerView == _fpsSelector.picker) {
        return 26;
    }
    return 0;
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    FPWCSApi2MediaDevice *device;
    if (pickerView == _micSelector.picker) {
        device = localDevices.audio[row];
        return device.label;
    } else if (pickerView == _camSelector.picker) {
        device = localDevices.video[row];
        return device.label;
    } else if (pickerView == _fpsSelector.picker) {
        return [NSString stringWithFormat:@"%d", (int)(row + 5)];
    }
    return 0;
}

- (void)onHideButton:(UIButton *)button {
    [_micSelector.input resignFirstResponder];
    [_camSelector.input resignFirstResponder];
    [_videoResolution.width resignFirstResponder];
    [_videoResolution.height resignFirstResponder];
    [_fpsSelector.input resignFirstResponder];
    [_bitrate.input resignFirstResponder];
    [_quality.input resignFirstResponder];
    [self hide];
}

- (void)controlValueChanged:(id)sender {
    if (sender == _sendAudio.control) {
        if (_sendAudio.control.isOn) {
            [self muteAudioInputs:NO];
        } else {
            [self muteAudioInputs:YES];
        }
    } else if (sender == _sendVideo.control) {
        if (_sendVideo.control.isOn) {
            [self muteVideoInputs:NO];
        } else {
            [self muteVideoInputs:YES];
        }
    }
}

 
- (void)muteAudioInputs:(BOOL)mute {
    BOOL enabled = !mute;
    _micSelector.input.userInteractionEnabled = enabled;
    _muteAudio.control.userInteractionEnabled = enabled;
}
 
- (void)muteVideoInputs:(BOOL)mute {
    BOOL enabled = !mute;
    _camSelector.input.userInteractionEnabled = enabled;
    _videoResolution.userInteractionEnabled = enabled;
    _fpsSelector.input.userInteractionEnabled = enabled;
    _bitrate.input.userInteractionEnabled = enabled;
    _quality.input.userInteractionEnabled = enabled;
    _muteVideo.control.userInteractionEnabled = enabled;
}

- (FPWCSApi2MediaConstraints *)toMediaConstraints {
    FPWCSApi2MediaConstraints *ret = [[FPWCSApi2MediaConstraints alloc] init];
    ret.audio = [_sendAudio.control isOn];
    if ([_sendVideo.control isOn]) {
        FPWCSApi2VideoConstraints *video = [[FPWCSApi2VideoConstraints alloc] init];
        for (FPWCSApi2MediaDevice *device in localDevices.video) {
            if ([device.label isEqualToString:_camSelector.input.text]) {
                video.deviceID = device.deviceID;
            }
        }
        video.minWidth = video.maxWidth = [_videoResolution.width.text integerValue];
        video.minHeight = video.maxHeight = [_videoResolution.height.text integerValue];
        video.minFrameRate = video.maxFrameRate = [_fpsSelector.input.text integerValue];
        video.bitrate = [_bitrate.input.text integerValue];
        video.quality = [_quality.input.text integerValue];
        ret.video = video;
    }
    return ret;
}

@end