//
//  AttendeeAdvertiser.h
//  TwitterMob
//
//  Created by Aleksey Novicov on 12/17/13.
//  Copyright (c) 2013 Yodel Code LLC. All rights reserved.
//

#import <CoreBluetooth/CoreBluetooth.h>
#import <Foundation/Foundation.h>

NSString* const kAttendeeServiceUUIDString;
NSString* const kCharacteristicTwitterIDUUIDString;

@interface AttendeeAdvertiser : NSObject <CBPeripheralManagerDelegate>

// The twitter ID will be broadcast as a BLE service
- (id)initWithTwitterID:(NSString *)twitterID;

- (void)stop;

@end
