//
//  RadTitleView.m
//  #renio
//
//  Created by Tim Burks on 11/13/13.
//  Copyright (c) 2013 Radtastical Inc. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import "RadTitleView.h"
#import "RadStyleManager.h"

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
        self.label.font = [UIFont fontWithName:@"AvenirNext-Bold"
                                          size:20.0*[[RadStyleManager sharedInstance] deviceTextScale]];
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

    CGFloat fullWidth;
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    CGRect windowBounds = [[UIScreen mainScreen] bounds];
    switch (orientation) {
        case UIInterfaceOrientationLandscapeLeft:
        case UIInterfaceOrientationLandscapeRight:
            fullWidth = windowBounds.size.height;
            break;
        case UIInterfaceOrientationPortrait:
        case UIInterfaceOrientationPortraitUpsideDown:
        default:
            fullWidth = windowBounds.size.width;
            break;
    }
    
    CGRect containerFrame = self.frame;
    CGFloat leftInset = containerFrame.origin.x;
    CGFloat rightInset = fullWidth - (containerFrame.origin.x+containerFrame.size.width);
    CGFloat inset = MAX(leftInset, rightInset);
    CGFloat subviewOrigin = inset-leftInset;
    CGFloat subviewWidth = fullWidth - 2*inset;
    
    CGRect subviewRect = self.label.frame;
    subviewRect.origin.x = subviewOrigin;
    subviewRect.size.width = subviewWidth;
    self.label.frame = subviewRect;
}

@end


