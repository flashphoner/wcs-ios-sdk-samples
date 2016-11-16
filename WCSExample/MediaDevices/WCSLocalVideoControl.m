

#import <FPWCSApi2/FPWCSApi2.h>
#import "WCSLocalVideoControl.h"
#import "WCSUtil.h"

@implementation WCSLocalVideoControlView {
    FPWCSApi2MediaDeviceList *localDevices;
}

- (instancetype)init {
    self = [super initWithPosition:NSLayoutAttributeLeft];
    if (self) {
        _hideButton = [WCSViewUtil createButton:@"Hide"];
        [_hideButton addTarget:self action:@selector(onHideButton:) forControlEvents:UIControlEventTouchUpInside];
        _sendAudio = [[WCSSwitchView alloc] initWithLabelText:@"Send Audio"];
        _micSelector = [[WCSPickerInputView alloc] initWithLabelText:@"Mic" pickerDelegate:self];
        _muteAudio = [[WCSSwitchView alloc] initWithLabelText:@"Mute Audio"];
        
        _border = [WCSViewUtil createBorder:@3];
        
        _sendVideo = [[WCSSwitchView alloc] initWithLabelText:@"Send Video"];
        _camSelector = [[WCSPickerInputView alloc] initWithLabelText:@"Cam" pickerDelegate:self];
        _videoResolution = [[WCSVideoResolutionInputView alloc] initWithLabelText:@"Size"];
        _fpsSelector = [[WCSPickerInputView alloc] initWithLabelText:@"FPS" pickerDelegate:self];
        _bitrate = [[WCSTextInputView alloc] initWithLabelText:@"Bitrate"];
        _quality = [[WCSTextInputView alloc] initWithLabelText:@"Quality"];
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
        
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-vSpacing-[hideButton]-vSpacing-[sendAudio]-vSpacing-[micSelector]-vSpacing-[muteAudio]-vSpacing-[border]-vSpacing-[sendVideo]-vSpacing-[camSelector]-vSpacing-[videoResolution]-vSpacing-[fpsSelector]-vSpacing-[bitrate]-vSpacing-[quality]" options:0 metrics:metrics views:views]];
        
        localDevices = [FPWCSApi2 getMediaDevices];
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
    } else if (pickerView == _fpsSelector.picker) {
        _fpsSelector.input.text = [NSString stringWithFormat:@"%d", (int)(row + 5)];
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
    [self hide];
}

 
- (void)muteAudioInputs:(BOOL)mute {
    
}
 
- (void)muteVideoInputs:(BOOL)mute {
    
}

@end