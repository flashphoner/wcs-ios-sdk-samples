
#import <UIKit/UIKit.h>
#import <FPWCSApi2/FPWCSApi2.h>

@interface WCSSlidingView : UIView

@property NSLayoutConstraint *padding;
@property BOOL visible;

- (instancetype)initWithPosition:(NSLayoutAttribute)position;

- (void)show;

- (void)hide;

@end

@interface WCSSwitchView : UIView

@property UILabel *label;
@property UISwitch *control;

- (instancetype)initWithLabelText:(NSString *)text;

@end

@interface WCSTextInputView : UIView

@property UILabel *label;
@property UITextField *input;

- (instancetype)initWithLabelText:(NSString *)text;

@end

@interface WCSTextInputWithDefaultView : WCSTextInputView

//todo add control label
@property UISwitch *control;

- (instancetype)initWithLabelText:(NSString *)text;

@end

@interface WCSDoubleVideoView : UIView<RTCEAGLVideoViewDelegate>

@property RTCEAGLVideoView *local;
@property RTCEAGLVideoView *remote;

@end

@interface WCSPickerInputView : WCSTextInputView

@property UIPickerView *picker;

- (instancetype)initWithLabelText:(NSString *)text pickerDelegate:(id)delegate;

@end

@interface WCSVideoResolutionInputView : UIView

@property UILabel *label;
@property UITextField *width;
@property UITextField *height;

- (instancetype)initWithLabelText:(NSString *)text;

@end

@interface WCSVideoResolutionInputWithDefaultView : WCSVideoResolutionInputView

//todo add control label
@property UISwitch *control;

- (instancetype)initWithLabelText:(NSString *)text;

@end


