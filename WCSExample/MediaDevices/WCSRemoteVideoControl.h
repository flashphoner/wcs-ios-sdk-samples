
#import "WCSViews.h"

@interface  WCSRemoteVideoControlView : WCSSlidingView<UITextFieldDelegate>

@property UIButton *hideButton;
@property WCSSwitchView *playVideo;
@property WCSVideoResolutionInputWithDefaultView *videoResolution;
@property WCSTextInputWithDefaultView *bitrate;
@property WCSTextInputWithDefaultView *quality;

- (void)muteVideoInputs:(BOOL)mute;

@end