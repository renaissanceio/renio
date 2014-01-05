//
//  Attendee.h
//  TwitterMob
//
//  Created by Aleksey Novicov on 12/5/13.
//  Copyright (c) 2013 Yodel Code LLC. All rights reserved.
//

#import <CoreBluetooth/CoreBluetooth.h>
#import "Attendee.h"

typedef enum {
    AttendeeRangeVeryFar,
    AttendeeRangeFar,
    AttendeeRangeNearby,
    AttendeeRangeClose,
    AttendeeRangeVeryClose
} AttendeeRange;

@class Attendee;

@protocol AttendeeDelegate <NSObject>
- (void)attendeeRangeChanged:(Attendee *)attendee;
- (void)attendeeTimeoutExpired:(Attendee *)attendee;
@end

@interface Attendee : NSObject 

@property (nonatomic, weak) id<AttendeeDelegate> delegate;
@property (nonatomic, strong) CBPeripheral *peripheral;
@property (nonatomic, strong) NSString *twitterID;
@property (nonatomic, strong) NSNumber *RSSI;
@property (nonatomic, assign) NSTimeInterval age;
@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, readonly) AttendeeRange range;
@property (nonatomic, readonly) UIColor *fillColor;
@property (nonatomic, readonly) BOOL isConnected;

- (BOOL)matchesAttendee:(Attendee *)attendee;
- (void)startTimer;
- (void)cancelTimer;

@end
