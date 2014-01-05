//
//  AttendeeBrowser.h
//  TwitterMob
//
//  Created by Aleksey Novicov on 12/17/13.
//  Copyright (c) 2013 Yodel Code LLC. All rights reserved.
//

#import <CoreBluetooth/CoreBluetooth.h>
#import <Foundation/Foundation.h>
#import "Attendee.h"

NSString * const PeripheralConnectionFailedNotification;

@interface AttendeeBrowser : NSObject <CBCentralManagerDelegate, CBPeripheralDelegate, AttendeeDelegate>

// An unsorted array of the currently visible attendees
@property (nonatomic, readonly) NSMutableArray *attendees;

// YES if the list of attendees, or their properties, have been recently updated. Clear after reading
@property (nonatomic, assign) BOOL updated;

// Returns YES if there were in fact old attendees that were removed
- (BOOL)removeOldAttendees;

// Stop browsing immediately
- (void)stop;

@end
