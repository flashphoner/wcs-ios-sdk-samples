
#import "WCSViews.h"
#import <FPWCSApi2/FPWCSApi2.h>

@interface  WCSRemoteVideoControlView : WCSSlidingView<UITextFieldDelegate>

@property UIButton *hideButton;
@property WCSSwitchView *playVideo;
@property WCSVideoResolutionInputWithDefaultView *videoResolution;
@property WCSTextInputWithDefaultView *bitrate;
@property WCSTextInputWithDefaultView *quality;

- (void)muteVideoInputs:(BOOL)mute;

- (FPWCSApi2MediaConstraints *)toMediaConstraints;

@end