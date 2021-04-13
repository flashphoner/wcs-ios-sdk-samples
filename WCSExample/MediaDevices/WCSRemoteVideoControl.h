
#import "WCSViews.h"
#import <FPWCSApi2/FPWCSApi2.h>

@interface  WCSRemoteVideoControlView : WCSSlidingView<UITextFieldDelegate>

@property UIScrollView *scrollView;
@property UIView *contentView;
@property UIButton *hideButton;
@property WCSSwitchView *playVideo;
@property WCSVideoResolutionInputWithDefaultView *videoResolution;
@property WCSTextInputWithDefaultView *bitrate;
@property WCSTextInputWithDefaultView *quality;
@property UILabel *audioMuted;
@property UILabel *videoMuted;

- (void)muteVideoInputs:(BOOL)mute;

- (FPWCSApi2MediaConstraints *)toMediaConstraints;

- (void)onAudioMute:(bool)muted;

- (void)onVideoMute:(bool)muted;

@end
