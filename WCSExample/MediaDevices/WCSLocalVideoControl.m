
#import "WCSLocalVideoControl.h"
#import "WCSUtil.h"

@implementation WCSLocalVideoControlView {
    FPWCSApi2MediaDeviceList *localDevices;
}

- (instancetype)init {
    self = [super initWithPosition:NSLayoutAttributeLeft];
    if (self) {
        localDevices = [FPWCSApi2 getMediaDevices];
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
        _fpsSelector = [[WCSPickerInputView alloc] initWithLabelText:@"FPS" pickerDelegate:self];
        //set default fps
        _fpsSelector.input.text = @"30";
        _bitrate = [[WCSTextInputView alloc] initWithLabelText:@"Bitrate"];
        _quality = [[WCSTextInputView alloc] initWithLabelText:@"Quality"];
        _muteVideo = [[WCSSwitchView alloc] initWithLabelText:@"Mute Video"];
        [self addSubview:_hideButton];
        [self addSubview:_sendAudio];
        [self addSubview:_micSelector];
        [self addSubview:_muteAudio];
        [self addSubview:_border];
        [self addSubview:_sendVideo];
        [self addSubview:_camSelector];
        [self addSubview:_videoResolution];
        [self addSubview:_fpsSelector];
        [self addSubview:_bitrate];
        [self addSubview:_quality];
        [self addSubview:_muteVideo];
        
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
                                @"container": self
                                };
        NSDictionary *metrics = @{
                                  @"height": @30,
                                  @"vSpacing": @10,
                                  @"hSpacing": @20
                                  };
        
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-hSpacing-[hideButton]-hSpacing-|" options:0 metrics:metrics views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-hSpacing-[sendAudio]-hSpacing-|" options:0 metrics:metrics views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-hSpacing-[micSelector]-hSpacing-|" options:0 metrics:metrics views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-hSpacing-[muteAudio]-hSpacing-|" options:0 metrics:metrics views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-hSpacing-[border]-hSpacing-|" options:0 metrics:metrics views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-hSpacing-[sendVideo]-hSpacing-|" options:0 metrics:metrics views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-hSpacing-[camSelector]-hSpacing-|" options:0 metrics:metrics views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-hSpacing-[videoResolution]-hSpacing-|" options:0 metrics:metrics views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-hSpacing-[fpsSelector]-hSpacing-|" options:0 metrics:metrics views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-hSpacing-[bitrate]-hSpacing-|" options:0 metrics:metrics views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-hSpacing-[quality]-hSpacing-|" options:0 metrics:metrics views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-hSpacing-[muteVideo]-hSpacing-|" options:0 metrics:metrics views:views]];
        
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-vSpacing-[hideButton]-vSpacing-[sendAudio]-vSpacing-[micSelector]-vSpacing-[muteAudio]-vSpacing-[border]-vSpacing-[sendVideo]-vSpacing-[camSelector]-vSpacing-[videoResolution]-vSpacing-[fpsSelector]-vSpacing-[bitrate]-vSpacing-[quality]-vSpacing-[muteVideo]" options:0 metrics:metrics views:views]];
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

@end