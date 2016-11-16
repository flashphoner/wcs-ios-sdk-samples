
#import <Foundation/Foundation.h>
#import "WCSViews.h"
#import "WCSUtil.h"

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
        [self setBackgroundColor:[UIColor whiteColor]];
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
        _input = [WCSViewUtil createTextField:nil];
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
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[label][textInput]|" options:NSLayoutFormatAlignAllTop metrics:metrics views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[label]" options:0 metrics:metrics views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[container(height)]" options:0 metrics:metrics views:views]];
        //width boundaries
        [self addConstraint:[NSLayoutConstraint constraintWithItem:_input attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeWidth multiplier:0.5 constant:0]];

    }
    return self;
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
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[label]|" options:0 metrics:metrics views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[textInput]|" options:0 metrics:metrics views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[control]|" options:0 metrics:metrics views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[container(height)]" options:0 metrics:metrics views:views]];
        [self addConstraint:[NSLayoutConstraint constraintWithItem:super.input attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeWidth multiplier:0.5 constant:0]];
        [self addConstraint:[NSLayoutConstraint constraintWithItem:super.input attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterX multiplier:1 constant:0]];
        [self addConstraint:[NSLayoutConstraint constraintWithItem:super.label attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeLeft multiplier:1 constant:0]];
        [self addConstraint:[NSLayoutConstraint constraintWithItem:_control attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeRight multiplier:1 constant:0]];


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
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.translatesAutoresizingMaskIntoConstraints = NO;
        _local = [[RTCEAGLVideoView alloc] init];
        _remote = [[RTCEAGLVideoView alloc] init];
        _local.translatesAutoresizingMaskIntoConstraints = NO;
        _remote.translatesAutoresizingMaskIntoConstraints = NO;
        
        [self addSubview:_local];
        [self addSubview:_remote];
        NSDictionary *views = @{
                                @"local": _local,
                                @"remote": _remote,
                                @"container": self
                                };
        NSDictionary *metrics = @{
                                  @"height": @30
                                  };
        [self addConstraint:[NSLayoutConstraint constraintWithItem:_local attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeLeft multiplier:1.0 constant:0]];
        [self addConstraint:[NSLayoutConstraint constraintWithItem:_remote attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeRight multiplier:1.0 constant:0]];
        [self addConstraint:[NSLayoutConstraint constraintWithItem:_local attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeTop multiplier:1.0 constant:0]];
        [self addConstraint:[NSLayoutConstraint constraintWithItem:_remote attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeTop multiplier:1.0 constant:0]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[local]" options:0 metrics:metrics views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[remote]" options:0 metrics:metrics views:views]];
        
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
        
    }
    return self;
}


+ (BOOL)requiresConstraintBasedLayout {
    return YES;
}

- (void)videoView:(RTCEAGLVideoView*)videoView didChangeVideoSize:(CGSize)size {
    if (videoView == _local) {
        NSLog(@"Size of local video %fx%f", size.width, size.height);
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
    } else {
        NSLog(@"Size of remote video %fx%f", size.width, size.height);
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
        _width = [WCSViewUtil createTextField:nil];
        _height = [WCSViewUtil createTextField:nil];
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
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[label][widthInput][heightInput]|" options:NSLayoutFormatAlignAllTop metrics:metrics views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[label]" options:0 metrics:metrics views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[container(height)]" options:0 metrics:metrics views:views]];

    }
    return self;
}

+ (BOOL)requiresConstraintBasedLayout {
    return YES;
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
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[label][widthInput][heightInput][control]|" options:NSLayoutFormatAlignAllTop metrics:metrics views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[label]" options:0 metrics:metrics views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[container(height)]" options:0 metrics:metrics views:views]];

        
    }
    return self;
}

@end


