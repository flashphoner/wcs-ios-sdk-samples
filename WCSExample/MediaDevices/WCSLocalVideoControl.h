
#import "WCSViews.h"

@interface  WCSLocalVideoControlView : WCSSlidingView<UITextFieldDelegate, UIPickerViewDelegate, UIPickerViewDataSource>

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

- (void)muteAudioInputs:(BOOL)mute;

- (void)muteVideoInputs:(BOOL)mute;

@end