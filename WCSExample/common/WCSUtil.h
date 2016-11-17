

#import <FPWCSApi2/FPWCSApi2.h>

#define IS_IPAD (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)

@interface WCSViewUtil : NSObject

+ (UITextField *)createTextField:(id)delegate;
+ (UITextView *)createTextView;
+ (UILabel *)createLabelView;
+ (UILabel *)createInfoLabel:(NSString *)infoText;
+ (UISwitch *)createSwitch;
+ (UIPickerView *)createPicker:(id)delegate;
+ (UIButton *)createButton:(NSString *)title;
+ (UIView *)createBorder:(NSNumber *)thickness;

@end