//
//  SmartTitleView.m
//  #renio
//
//  Created by Tim Burks on 11/13/13.
//  Copyright (c) 2013 Radtastical Inc. All rights reserved.
//

#import "RadTitleView.h"



@interface RadTitleView ()
@property (nonatomic, strong) UILabel *label;
@end

@implementation RadTitleView

- (id) initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        self.label = [[UILabel alloc] initWithFrame:self.bounds];
        self.label.adjustsFontSizeToFitWidth = YES;
        self.label.textAlignment = NSTextAlignmentCenter;
        self.label.numberOfLines = 0;
        self.label.textColor = [UIColor whiteColor];
        self.label.font = [UIFont fontWithName:@"AvenirNext-Bold" size:20.0];
        //self.backgroundColor = [UIColor yellowColor];
        //self.label.backgroundColor = [UIColor redColor];
        [self addSubview:self.label];
    }
    return self;
}

- (void) setText:(NSString *) text
{
    self.label.text = text;
}

- (void) layoutSubviews
{
    [super layoutSubviews];
    UIView *subview = self.label;
    CGRect containerFrame = self.frame;
    CGRect parentFrame = [self superview].frame;
    CGFloat fullWidth = parentFrame.size.width;
    CGFloat leftInset = containerFrame.origin.x;
    CGFloat rightInset = fullWidth - (containerFrame.origin.x+containerFrame.size.width);
    CGFloat inset = MAX(leftInset, rightInset);
    CGFloat subviewOrigin = inset-leftInset;
    CGFloat subviewWidth = fullWidth - 2*inset;
    CGRect subviewRect = subview.frame;
    subviewRect.origin.x = subviewOrigin;
    subviewRect.size.width = subviewWidth;
    subview.frame = subviewRect;
}

@end


