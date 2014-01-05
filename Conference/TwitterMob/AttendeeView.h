//
//  AttendeeView.h
//  TwitterMob
//
//  Created by Aleksey Novicov on 11/23/13.
//  Copyright (c) 2013 Yodel Code LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Attendee.h"

@interface AttendeeView : UIView

@property (nonatomic, strong) Attendee *attendee;
@property (nonatomic, assign) BOOL pulseEnabled;

- (void)update;

@end
