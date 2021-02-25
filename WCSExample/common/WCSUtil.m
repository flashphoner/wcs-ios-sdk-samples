//
//  WCSExampleUtil.m
//  WCSExample
//
//  Created by flashphoner on 14/11/2016.
//  Copyright © 2016 flashphoner. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WCSUtil.h"

@implementation WCSViewUtil

+ (void)updateBackgroundColor:(UIViewController *)viewController{
    if (@available(iOS 13.0, *)) {
        viewController.view.backgroundColor = [UIColor systemBackgroundColor];
    }
}

+ (UITextField *)createTextField:(id)delegate{
    UITextField *textField = [[UITextField alloc] init];
    textField.borderStyle = UITextBorderStyleRoundedRect;
    textField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    [textField setFont:[UIFont boldSystemFontOfSize:12]];
    textField.translatesAutoresizingMaskIntoConstraints = NO;
    [textField setReturnKeyType:UIReturnKeyDone];
    textField.delegate = delegate;
    return textField;
    
}

+ (UITextView *)createTextView {
    UITextView *textView = [[UITextView alloc] init];
    [textView setFont:[UIFont boldSystemFontOfSize:12]];
    textView.translatesAutoresizingMaskIntoConstraints = NO;
    textView.textAlignment = NSTextAlignmentCenter;
    textView.editable = NO;
    textView.text = @"NO STATUS";
    return textView;
}


+ (UILabel *)createLabelView {
    UILabel *textView = [[UILabel alloc] init];
    [textView setFont:[UIFont boldSystemFontOfSize:12]];
    textView.translatesAutoresizingMaskIntoConstraints = NO;
    textView.textAlignment = NSTextAlignmentCenter;
    textView.text = @"NO STATUS";
    if (@available(iOS 13.0, *)) {
        textView.textColor = UIColor.labelColor;
    }
    return textView;
}

+ (UILabel *)createInfoLabel:(NSString *)infoText {
    UILabel *label = [[UILabel alloc] init];
    [label setFont:[UIFont boldSystemFontOfSize:12]];
    label.translatesAutoresizingMaskIntoConstraints = NO;
    label.textAlignment = NSTextAlignmentLeft;
    label.text = infoText;
    if (@available(iOS 13.0, *)) {
        label.textColor = UIColor.labelColor;
    }
    return label;
}

+ (UISwitch *)createSwitch {
    UISwitch *uiSwitch = [[UISwitch alloc] init];
    uiSwitch.translatesAutoresizingMaskIntoConstraints = NO;
    return uiSwitch;
}

+ (UIPickerView *)createPicker:(id)delegate {
    UIPickerView *picker = [[UIPickerView alloc] init];
    picker.dataSource = delegate;
    picker.delegate = delegate;
    picker.showsSelectionIndicator = YES;
    return picker;
}

+ (UIButton *)createButton:(NSString *)title {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    [button setBackgroundColor:[UIColor lightGrayColor]];
    [button.layer setBorderWidth:2.0];
    [button.layer setCornerRadius:6.0];
    [button setTitle:title forState:UIControlStateNormal];
    button.translatesAutoresizingMaskIntoConstraints = NO;
    return button;
}

+ (UIView *)createBorder:(NSNumber *)thickness {
    UIView *border = [[UIView alloc] init];
    border.translatesAutoresizingMaskIntoConstraints = NO;
    [border setBackgroundColor:[UIColor blackColor]];
    [border addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[border(thickness)]" options:0 metrics:@{@"thickness": thickness} views:@{@"border": border}]];
    return border;
}


@end

@interface WCSStack()
@property (strong) NSMutableArray *data;
@end

@implementation WCSStack

-(id)init{
    if (self=[super init]){
        _data = [[NSMutableArray alloc] init];
        _count = 0;
    }
    return  self;
}

-(void)push:(id)anObject
{
    [self.data addObject:anObject];
    _count++;
}

-(id)pop{
    id obj = nil;
    if ([self.data count] > 0){
        obj = [self.data lastObject];
        [self.data removeLastObject];
        _count = self.data.count;
    }
    return obj;
}

-(void)clear{
    [self.data removeAllObjects];
    _count = 0;
}

-(id)lastObject{
    id obj = nil;
    if ([self.data count] > 0){
        obj = [self.data lastObject];
    }
    return obj;
}

@end
