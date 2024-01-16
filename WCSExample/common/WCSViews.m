
#import <Foundation/Foundation.h>
#import "WCSViews.h"
#import "WCSUtil.h"

@implementation WCSKeyboardTracker {
    UITextField *_activeField;
    UIScrollView *_activeScroll;
}

+ (instancetype)sharedInstance
{
    static WCSKeyboardTracker *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[WCSKeyboardTracker alloc] init];
        [sharedInstance registerForKeyboardNotifications];
    });
    return sharedInstance;
}

- (void)update:(UITextField *)field {
    if (_activeField) {
        [self keyboardWillBeHidden:nil];
    }
    _activeField = field;
    _activeScroll = [self findParentScroll:field];
}

- (UIScrollView *)findParentScroll:(UIView *)child {
    if (child && child.superview) {
        if ([child.superview isKindOfClass:[UIScrollView class]]) {
            return (UIScrollView *)child.superview;
        } else {
            return [self findParentScroll:child.superview];
        }
    }
    return nil;
}

- (void)update {
    [self update:nil];
}

- (void)registerForKeyboardNotifications {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWasShown:)
                                                 name:UIKeyboardDidShowNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillBeHidden:)
                                                 name:UIKeyboardWillHideNotification object:nil];
    
}


- (void)keyboardWasShown:(NSNotification*)aNotification {
    if (_activeField && _activeScroll) {
        NSDictionary* info = [aNotification userInfo];
        CGSize kbSize = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
        
        UIEdgeInsets contentInsets = UIEdgeInsetsMake(0.0, 0.0, kbSize.height, 0.0);
        _activeScroll.contentInset = contentInsets;
        _activeScroll.scrollIndicatorInsets = contentInsets;
        
        // If active text field is hidden by keyboard, scroll it so it's visible
        // Your app might not need or want this behavior.
        CGRect aRect = _activeScroll.superview.frame;
        aRect.size.height -= kbSize.height;
        if (!CGRectContainsPoint(aRect, _activeField.frame.origin) ) {
            [_activeScroll scrollRectToVisible:_activeField.frame animated:YES];
        }
    }
}

- (void)keyboardWillBeHidden:(NSNotification*)aNotification {
    if (_activeField && _activeScroll) {
        UIEdgeInsets contentInsets = UIEdgeInsetsZero;
        _activeScroll.contentInset = contentInsets;
        _activeScroll.scrollIndicatorInsets = contentInsets;
    }
}


@end

@implementation WCSSlidingView {
    NSLayoutAttribute position;
    CGFloat paddingHide;
}

- (instancetype)init {
    return [self initWithPosition:NSLayoutAttributeBottom];
}

- (instancetype)initWithPosition:(NSLayoutAttribute)pos {
    self = [super init];
    if (self) {
        self.translatesAutoresizingMaskIntoConstraints = NO;
        if (@available(iOS 13.0, *)) {
            [self setBackgroundColor:[UIColor systemBackgroundColor]];
        } else {
            [self setBackgroundColor:[UIColor whiteColor]];
        }
        position = pos;
        paddingHide = (pos == NSLayoutAttributeBottom || pos == NSLayoutAttributeRight) ? 2000 : -2000;
    }
    return self;
}

+ (BOOL)requiresConstraintBasedLayout {
    return YES;
}

- (void)updateConstraints {
    if (!_padding) {
        _padding = [NSLayoutConstraint constraintWithItem:self
                                                attribute:position
                                                relatedBy:NSLayoutRelationEqual
                                                   toItem:self.superview
                                                attribute:position
                                               multiplier:1.0
                                                 constant:paddingHide];
        [self.superview addConstraint:_padding];
        if (position == NSLayoutAttributeLeft || position == NSLayoutAttributeRight) {
            [self.superview addConstraint:[NSLayoutConstraint constraintWithItem:self
                                                                       attribute:NSLayoutAttributeWidth
                                                                       relatedBy:NSLayoutRelationEqual
                                                                          toItem:self.superview
                                                                       attribute:NSLayoutAttributeWidth
                                                                      multiplier:0.5
                                                                        constant:0]];
        } else {
            [self.superview addConstraint:[NSLayoutConstraint constraintWithItem:self
                                                                       attribute:NSLayoutAttributeHeight
                                                                       relatedBy:NSLayoutRelationEqual
                                                                          toItem:self.superview
                                                                       attribute:NSLayoutAttributeHeight
                                                                      multiplier:0.5
                                                                        constant:0]];
        }
        _visible = NO;
    }
    [super updateConstraints];
}



- (void)show {
    _padding.constant = 0;
    [self.superview setNeedsUpdateConstraints];
    
    [UIView animateWithDuration:.4 animations:^{
        [self.superview layoutIfNeeded];
        _visible = YES;
    }];
}

- (void)hide {
    _padding.constant = paddingHide;
    [self.superview setNeedsUpdateConstraints];
    
    [UIView animateWithDuration:.4 animations:^{
        [self.superview layoutIfNeeded];
        _visible = NO;
    }];
}

@end

@implementation WCSSwitchView

- (instancetype)init {
    return [self initWithLabelText:@"Toggle"];
}

- (instancetype)initWithLabelText:(NSString *)text {
    self = [super init];
    if (self) {
        self.translatesAutoresizingMaskIntoConstraints = NO;
        _label = [WCSViewUtil createInfoLabel:text];
        _control = [WCSViewUtil createSwitch];
        [self addSubview:_label];
        [self addSubview:_control];
        //add constraints
        NSDictionary *views = @{
                                @"label": _label,
                                @"control": _control,
                                @"container": self
                                };
        NSDictionary *metrics = @{
                                  @"height": @30
                                  };
        [_label addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[label(height)]" options:0 metrics:metrics views:views]];
        [_control addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[control(height)]" options:0 metrics:metrics views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[label][control]|" options:NSLayoutFormatAlignAllTop metrics:metrics views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[label]" options:0 metrics:metrics views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[container(height)]" options:0 metrics:metrics views:views]];
        
    }
    return self;
}


+ (BOOL)requiresConstraintBasedLayout {
    return YES;
}

- (void)updateConstraints {
    [super updateConstraints];
}

- (void)didMoveToSuperview {
    [super didMoveToSuperview];
}

@end

@implementation WCSTextInputView

- (instancetype)init {
    return [self initWithLabelText:@"TextInput"];
}

- (instancetype)initWithLabelText:(NSString *)text {
    self = [super init];
    if (self) {
        self.translatesAutoresizingMaskIntoConstraints = NO;
        _label = [WCSViewUtil createInfoLabel:text];
        _input = [WCSViewUtil createTextField:self];
        //add constraints
        NSDictionary *views = @{
                                @"label": _label,
                                @"textInput": _input,
                                @"container": self
                                };
        NSDictionary *metrics = @{
                                  @"height": @30
                                  };

        [self addSubview:_label];
        [self addSubview:_input];
        [_label addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[label(height)]" options:0 metrics:metrics views:views]];
        [_input addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[textInput(height)]" options:0 metrics:metrics views:views]];
        if (IS_IPAD) {
            [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[label][textInput]|" options:NSLayoutFormatAlignAllTop metrics:metrics views:views]];
            [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[label]" options:0 metrics:metrics views:views]];
            [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[container(height)]" options:0 metrics:metrics views:views]];
            //width boundaries
            [self addConstraint:[NSLayoutConstraint constraintWithItem:_input attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeWidth multiplier:0.5 constant:0]];
        } else {
            [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[label]|" options:NSLayoutFormatAlignAllTop metrics:metrics views:views]];
            [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[textInput]|" options:NSLayoutFormatAlignAllTop metrics:metrics views:views]];
            [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[label]-2-[textInput]|" options:0 metrics:metrics views:views]];
        }

    }
    return self;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    [[WCSKeyboardTracker sharedInstance] update:textField];
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    [[WCSKeyboardTracker sharedInstance] update];
}

+ (BOOL)requiresConstraintBasedLayout {
    return YES;
}

@end

@implementation WCSTextInputWithDefaultView

- (instancetype)init {
    return [self initWithLabelText:@"TextInput"];
}

- (instancetype)initWithLabelText:(NSString *)text{
    self = [super initWithLabelText:text];
    if (self) {
        _control = [WCSViewUtil createSwitch];
        [self addSubview:_control];
        NSDictionary *views = @{
                                @"label": super.label,
                                @"textInput": super.input,
                                @"control": _control,
                                @"container": self
                                };
        NSDictionary *metrics = @{
                                  @"height": @30
                                  };
        [_control addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[control(height)]" options:0 metrics:metrics views:views]];
        [self removeConstraints:[self constraints]];
        if (IS_IPAD) {
            [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[label]|" options:0 metrics:metrics views:views]];
            [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[textInput]|" options:0 metrics:metrics views:views]];
            [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[control]|" options:0 metrics:metrics views:views]];
            [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[container(height)]" options:0 metrics:metrics views:views]];
            [self addConstraint:[NSLayoutConstraint constraintWithItem:super.input attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeWidth multiplier:0.5 constant:0]];
            [self addConstraint:[NSLayoutConstraint constraintWithItem:super.input attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterX multiplier:1 constant:0]];
            [self addConstraint:[NSLayoutConstraint constraintWithItem:super.label attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeLeft multiplier:1 constant:0]];
            [self addConstraint:[NSLayoutConstraint constraintWithItem:_control attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeRight multiplier:1 constant:0]];
        } else {
            [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[label][control]|" options:NSLayoutFormatAlignAllTop metrics:metrics views:views]];
            [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[textInput]|" options:0 metrics:metrics views:views]];
            [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[label]-2-[textInput]|" options:0 metrics:metrics views:views]];
        }


    }
    return self;
}


+ (BOOL)requiresConstraintBasedLayout {
    return YES;
}

@end

@implementation WCSDoubleVideoView {
    NSMutableArray *localConstraints;
    NSMutableArray *remoteConstraints;
    UILabel *_localLabel;
    UILabel *_remoteLabel;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        localConstraints = [[NSMutableArray alloc] init];
        remoteConstraints = [[NSMutableArray alloc] init];
        self.translatesAutoresizingMaskIntoConstraints = NO;
        _local = [[RTCMTLVideoView alloc] init];
        _remote = [[RTCMTLVideoView alloc] init];
        _local.translatesAutoresizingMaskIntoConstraints = NO;
        _remote.translatesAutoresizingMaskIntoConstraints = NO;
        _localLabel = [WCSViewUtil createLabelView];
        _localLabel.text = @"0x0";
        _remoteLabel = [WCSViewUtil createLabelView];
        _remoteLabel.text = @"0x0";
        [self addSubview:_local];
        [self addSubview:_remote];
        [self addSubview:_localLabel];
        [self addSubview:_remoteLabel];
        NSDictionary *views = @{
                                @"local": _local,
                                @"remote": _remote,
                                @"localLabel": _localLabel,
                                @"remoteLabel": _remoteLabel,
                                @"container": self
                                };
        NSDictionary *metrics = @{
                                  @"height": @30
                                  };
        [_localLabel addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[localLabel(height)]" options:0 metrics:metrics views:views]];
        [_remoteLabel addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[remoteLabel(height)]" options:0 metrics:metrics views:views]];
        [self addConstraint:[NSLayoutConstraint constraintWithItem:_local attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeLeft multiplier:1.0 constant:0]];
        [self addConstraint:[NSLayoutConstraint constraintWithItem:_remote attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeRight multiplier:1.0 constant:0]];
        [self addConstraint:[NSLayoutConstraint constraintWithItem:_local attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeTop multiplier:1.0 constant:0]];
        [self addConstraint:[NSLayoutConstraint constraintWithItem:_remote attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeTop multiplier:1.0 constant:0]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[local]" options:0 metrics:metrics views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[remote]" options:0 metrics:metrics views:views]];
        [self addConstraint:[NSLayoutConstraint constraintWithItem:_localLabel attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:_local attribute:NSLayoutAttributeBottom multiplier:1.0 constant:20]];
        [self addConstraint:[NSLayoutConstraint constraintWithItem:_remoteLabel attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:_remote attribute:NSLayoutAttributeBottom multiplier:1.0 constant:20]];
        [self addConstraint:[NSLayoutConstraint constraintWithItem:_localLabel attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:_local attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0]];
        [self addConstraint:[NSLayoutConstraint constraintWithItem:_remoteLabel attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:_remote attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0]];
        [self addConstraint:[NSLayoutConstraint constraintWithItem:_localLabel attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationLessThanOrEqual toItem:self attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0]];
        [self addConstraint:[NSLayoutConstraint constraintWithItem:_remoteLabel attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationLessThanOrEqual toItem:self attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0]];
        //aspect ratio
        NSLayoutConstraint *localARConstraint = [NSLayoutConstraint constraintWithItem:_local attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:_local attribute:NSLayoutAttributeHeight multiplier:640.0/480.0 constant:0];
        [localConstraints addObject:localARConstraint];
        [_local addConstraint:localARConstraint];
        
        //height boundaries
        [self addConstraint:[NSLayoutConstraint constraintWithItem:_local attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationLessThanOrEqual toItem:self attribute:NSLayoutAttributeHeight multiplier:1.0 constant:0]];
        
        [self addConstraint:[NSLayoutConstraint constraintWithItem:_local attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationLessThanOrEqual toItem:self attribute:NSLayoutAttributeWidth multiplier:0.48 constant:0]];
        NSLayoutConstraint *localHeight = [NSLayoutConstraint constraintWithItem:_local attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeHeight multiplier:1.0 constant:0];
        localHeight.priority = 999;
        [self addConstraint:localHeight];
        
        //aspect ratio
        NSLayoutConstraint *remoteARConstraint = [NSLayoutConstraint constraintWithItem:_remote attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:_remote attribute:NSLayoutAttributeHeight multiplier:640.0/480.0 constant:0];
        [remoteConstraints addObject:remoteARConstraint];
        [_remote addConstraint:remoteARConstraint];
        
        //height boundaries
        [self addConstraint:[NSLayoutConstraint constraintWithItem:_remote attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationLessThanOrEqual toItem:self attribute:NSLayoutAttributeHeight multiplier:1.0 constant:0]];
        
        //width boundaries
        [self addConstraint:[NSLayoutConstraint constraintWithItem:_remote attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationLessThanOrEqual toItem:self attribute:NSLayoutAttributeWidth multiplier:0.48 constant:0]];
        
        NSLayoutConstraint *remoteHeight = [NSLayoutConstraint constraintWithItem:_remote attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeHeight multiplier:1.0 constant:0];
        remoteHeight.priority = 999;
        [self addConstraint:remoteHeight];
        _local.delegate = self;
        _remote.delegate = self;
        
    }
    return self;
}


+ (BOOL)requiresConstraintBasedLayout {
    return YES;
}

- (void)videoView:(RTCMTLVideoView*)videoView didChangeVideoSize:(CGSize)size {
    if (videoView == _local) {
        _localLabel.text = [NSString stringWithFormat:@"%fx%f", size.width, size.height];
        [_local removeConstraints:localConstraints];
        [localConstraints removeAllObjects];
        NSLayoutConstraint *constraint =[NSLayoutConstraint
                                         constraintWithItem:_local
                                         attribute:NSLayoutAttributeWidth
                                         relatedBy:NSLayoutRelationEqual
                                         toItem:_local
                                         attribute:NSLayoutAttributeHeight
                                         multiplier:size.width/size.height
                                         constant:0.0f];
        [localConstraints addObject:constraint];
        [_local addConstraints:localConstraints];
        _localLabel.text = [NSString stringWithFormat:@"%dx%d", (int)size.width, (int)size.height];
    } else {
        _remoteLabel.text = [NSString stringWithFormat:@"%dx%d", (int)size.width, (int)size.height];
        [_remote removeConstraints:remoteConstraints];
        [remoteConstraints removeAllObjects];
        NSLayoutConstraint *constraint =[NSLayoutConstraint
                                         constraintWithItem:_remote
                                         attribute:NSLayoutAttributeWidth
                                         relatedBy:NSLayoutRelationEqual
                                         toItem:_remote
                                         attribute:NSLayoutAttributeHeight
                                         multiplier:size.width/size.height
                                         constant:0.0f];
        [remoteConstraints addObject:constraint];
        [_remote addConstraints:remoteConstraints];
    }
}


@end

@implementation WCSPickerInputView

- (instancetype)init {
    return [self initWithLabelText:@"Picker" pickerDelegate:nil];
}

- (instancetype)initWithLabelText:(NSString *)text pickerDelegate:(id)delegate {
    self = [super initWithLabelText:text];
    if (self) {
        _picker = [[UIPickerView alloc] init];
        _picker.showsSelectionIndicator = YES;
        _picker.dataSource = delegate;
        _picker.delegate = delegate;
        super.input.inputView = _picker;
    }
    return self;
}

@end

@implementation WCSVideoResolutionInputView

- (instancetype)init {
    return [self initWithLabelText:@"Resolution"];
}

- (instancetype)initWithLabelText:(NSString *)text {
    self = [super init];
    if (self) {
        self.translatesAutoresizingMaskIntoConstraints = NO;
        _label = [WCSViewUtil createInfoLabel:text];
        _width = [WCSViewUtil createTextField:self];
        _width.textAlignment = NSTextAlignmentCenter;
        _height = [WCSViewUtil createTextField:self];
        _height.textAlignment = NSTextAlignmentCenter;
        [self addSubview:_label];
        [self addSubview:_width];
        [self addSubview:_height];
        
        NSDictionary *views = @{
                                @"label": _label,
                                @"widthInput": _width,
                                @"heightInput": _height,
                                @"container": self
                                };
        NSDictionary *metrics = @{
                                  @"height": @30
                                  };
        [_label addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[label(height)]" options:0 metrics:metrics views:views]];
        [_width addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[widthInput(height)]" options:0 metrics:metrics views:views]];
        [_height addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[heightInput(height)]" options:0 metrics:metrics views:views]];
        if (IS_IPAD) {
            [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[label][widthInput][heightInput(==widthInput)]|" options:NSLayoutFormatAlignAllTop metrics:metrics views:views]];
            [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[label]" options:0 metrics:metrics views:views]];
            [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[container(height)]" options:0 metrics:metrics views:views]];
        } else {
            [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[label]|" options:0 metrics:metrics views:views]];
            [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[widthInput][heightInput(==widthInput)]|" options:NSLayoutFormatAlignAllTop metrics:metrics views:views]];
            [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[label]-2-[widthInput]|" options:0 metrics:metrics views:views]];
        }

    }
    return self;
}

+ (BOOL)requiresConstraintBasedLayout {
    return YES;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    if (!string.length) {
        return YES;
    }
    

    NSString *newString = [textField.text stringByReplacingCharactersInRange:range withString:string];
    NSString *expression = @"^([0-9]+)?(\\.([0-9]{1,2})?)?$";
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:expression
                                                                               options:NSRegularExpressionCaseInsensitive
                                                                                 error:nil];
    NSUInteger numberOfMatches = [regex numberOfMatchesInString:newString
                                                            options:0
                                                              range:NSMakeRange(0, [newString length])];
    if (numberOfMatches == 0) {
            return NO;
    }
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    [[WCSKeyboardTracker sharedInstance] update:textField];
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    [[WCSKeyboardTracker sharedInstance] update];
}


@end

@implementation WCSVideoResolutionInputWithDefaultView

- (instancetype)init {
    return [self initWithLabelText:@"Resolution"];
}

- (instancetype)initWithLabelText:(NSString *)text {
    self = [super initWithLabelText:text];
    if (self) {
        _control = [WCSViewUtil createSwitch];
        [self addSubview:_control];
        NSDictionary *views = @{
                                @"label": super.label,
                                @"widthInput": super.width,
                                @"heightInput": super.height,
                                @"control": _control,
                                @"container": self
                                };
        NSDictionary *metrics = @{
                                  @"height": @30
                                  };
        [_control addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[control(height)]" options:0 metrics:metrics views:views]];
        [self removeConstraints:[self constraints]];
        if (IS_IPAD) {
            [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[label][widthInput][heightInput][control]|" options:NSLayoutFormatAlignAllTop metrics:metrics views:views]];
            [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[label]" options:0 metrics:metrics views:views]];
            [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[container(height)]" options:0 metrics:metrics views:views]];
        } else {
            [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[label][control]|" options:NSLayoutFormatAlignAllTop metrics:metrics views:views]];
            [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[widthInput][heightInput(==widthInput)]|" options:NSLayoutFormatAlignAllTop metrics:metrics views:views]];
            [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[label]-2-[widthInput]|" options:0 metrics:metrics views:views]];
        }

        
    }
    return self;
}

@end


