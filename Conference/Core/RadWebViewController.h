//
//  WebViewController.h
//  #renio
//
//  Created by Tim Burks on 11/9/13.
//  Copyright (c) 2013 Radtastical Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RadWebViewController : UIViewController

- (instancetype) initWithParameterString:(NSString *) string;

- (void) loadPath:(NSString *) path;

@end
