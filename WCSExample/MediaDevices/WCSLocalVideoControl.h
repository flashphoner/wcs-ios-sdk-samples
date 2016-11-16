
#import "WCSViews.h"
#import <FPWCSApi2/FPWCSApi2.h>

@interface  WCSLocalVideoControlView : WCSSlidingView<UITextFieldDelegate, UIPickerViewDelegate, UIPickerViewDataSource>

@property UIView *scrollView;
@property UIView *contentView;
@property UIButton *hideButton;
@property WCSSwitchView *sendAudio;
@property WCSPickerInputView *micSelector;
@property WCSSwitchView *muteAudio;

@property UIView *border;
@property WCSSwitchView *sendVideo;
@property WCSPickerInputView *camSelector;
@property WCSVideoResolutionInputView *videoResolution;
@property WCSPickerInputView *fpsSelector;
@property WCSTextInputView *bitrate;
@property WCSTextInputView *quality;
@property WCSSwitchView *muteVideo;

- (void)muteAudioInputs:(BOOL)mute;

- (void)muteVideoInputs:(BOOL)mute;

- (FPWCSApi2MediaConstraints *)toMediaConstraints;

@end