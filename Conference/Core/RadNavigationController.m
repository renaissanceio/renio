//
//  RadNavigationController.m
//  #renio
//
//  Created by Tim Burks on 11/13/13.
//  Copyright (c) 2013 Radtastical Inc. All rights reserved.
//

#import "RadNavigationController.h"

@interface RadNavigationController ()

@end

@implementation RadNavigationController

- (instancetype) initWithRootViewController:(UIViewController *)rootViewController
{
    if (self = [super initWithRootViewController:rootViewController]) {
        self.navigationBar.tintColor = [UIColor whiteColor];
    }
    return self;
}

- (UIStatusBarStyle) preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

@end
