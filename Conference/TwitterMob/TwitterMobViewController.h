//
//  TwitterMobViewController.h
//  TwitterMob
//
//  Created by Aleksey Novicov on 11/23/13.
//  Copyright (c) 2013 Yodel Code LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TwitterMobViewController : UIViewController <UIScrollViewDelegate>

@property (weak, nonatomic) IBOutlet UILabel *versionLabel;

// Single point of entry into Twitter Mob app. The initial view controller
// is actually a UINavigationController that is intended to be presented
// modally or as the initial view controller for a UITabViewController.

+ (UINavigationController *)initialViewController;

@end
