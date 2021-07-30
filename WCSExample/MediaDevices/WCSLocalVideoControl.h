
#import "WCSViews.h"
#import <FPWCSApi2/FPWCSApi2.h>

@interface  WCSLocalVideoControlView : WCSSlidingView<UITextFieldDelegate, UIPickerViewDelegate, UIPickerViewDataSource>

@property UIScrollView *scrollView;
@property UIView *contentView;
@property UIButton *hideButton;
@property WCSSwitchView *sendAudio;
@property WCSPickerInputView *micSelector;
@property WCSSwitchView *useFEC;
@property WCSSwitchView *useStereo;
@property WCSTextInputView *audioBitrate;
@property WCSSwitchView *muteAudio;

@property UIView *border;
@property WCSSwitchView *sendVideo;
@property WCSPickerInputView *camSelector;
@property WCSPickerInputView *videoResolutionSelector;
@property WCSPickerInputView *fpsSelector;
@property WCSTextInputView *minVideoBitrate;
@property WCSTextInputView *maxVideoBitrate;
@property WCSSwitchView *muteVideo;

- (void)muteAudioInputs:(BOOL)mute;

- (void)muteVideoInputs:(BOOL)mute;

- (FPWCSApi2MediaConstraints *)toMediaConstraints;

@end
