//
//  SmartTableViewController.h
//  #renio
//
//  Created by Tim Burks on 11/8/13.
//  Copyright (c) 2013 Radtastical Inc Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RadTextField : UITextField
@property (nonatomic, strong) NSString *formId;
@property (nonatomic, strong) NSString *itemId;
@end

@interface RadTextView : UITextView
@property (nonatomic, strong) NSString *formId;
@property (nonatomic, strong) NSString *itemId;
@end

@interface RadSlider : UISlider
@property (nonatomic, strong) NSString *formId;
@property (nonatomic, strong) NSString *itemId;
@end

@interface RadTableViewController : UITableViewController <UITextViewDelegate, UITextFieldDelegate>
@property (nonatomic, strong) NSDictionary *contents;

- (instancetype) initWithParameterString:(NSString *) parameterString;
- (void) push:(UIViewController *) viewController;
@end
