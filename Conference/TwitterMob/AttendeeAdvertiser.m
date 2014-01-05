//
//  AttendeeAdvertiser.m
//  TwitterMob
//
//  Created by Aleksey Novicov on 12/17/13.
//  Copyright (c) 2013 Yodel Code LLC. All rights reserved.
//

#import "AttendeeAdvertiser.h"

#define NOTIFY_MTU	20

// For Renaissance Conference only!
NSString* const kAttendeeServiceUUIDString			= @"88B477FB-6CA7-4F9C-A191-CE324C200C51";

//NSString* const kAttendeeServiceUUIDString			= @"2C593601-DC31-4A04-9B80-063EC858ED5A";
NSString* const kCharacteristicTwitterIDUUIDString	= @"FD94EED4-769C-4F1A-A3C1-7A5F17D40C8F";


@interface AttendeeAdvertiser ()
@property (nonatomic, copy) NSString *twitterID;
@end


@implementation AttendeeAdvertiser {
	CBPeripheralManager		*peripheralManager;
	CBMutableService		*attendeeService;
	CBMutableCharacteristic	*twitterIDCharacteristic;
}

- (id)initWithTwitterID:(NSString *)twitterID {
	self = [super init];
	
	if (self) {
		peripheralManager = [[CBPeripheralManager alloc] initWithDelegate:self queue:nil];
		_twitterID = twitterID;
	}
	return self;
}

- (void)stop {
	[peripheralManager stopAdvertising];
	[peripheralManager removeAllServices];
}

#pragma mark - Private methods

- (void)setupService {
	CBUUID *cbuuidService	= [CBUUID UUIDWithString:kAttendeeServiceUUIDString];
	CBUUID *cbuuidTwitterID	= [CBUUID UUIDWithString:kCharacteristicTwitterIDUUIDString];
	
	// Setup the twitterID characteristic representing an attendee
	
	twitterIDCharacteristic = [[CBMutableCharacteristic alloc] initWithType: cbuuidTwitterID
																 properties: CBCharacteristicPropertyRead
																	  value: [self.twitterID dataUsingEncoding:NSUTF8StringEncoding]
																permissions: CBAttributePermissionsReadable];
	
	attendeeService = [[CBMutableService alloc] initWithType:cbuuidService primary:YES];
	attendeeService.characteristics = @[twitterIDCharacteristic];
	
	[peripheralManager addService:attendeeService];
}

- (void)advertise {
	CBUUID *cbuuidService = [CBUUID UUIDWithString:kAttendeeServiceUUIDString];
	
	// Advertise with pseudonym as well, though it might not always fit
	NSDictionary *dictionary = @{CBAdvertisementDataServiceUUIDsKey: @[cbuuidService], CBAdvertisementDataLocalNameKey: self.twitterID};
	[peripheralManager startAdvertising:dictionary];
}

#pragma mark - CBPeripheralManagerDelegate

- (void)peripheralManagerDidStartAdvertising:(CBPeripheralManager *)peripheral error:(NSError *)error {
	if (error) {
		DLog(@"Advertising error: %@", error.localizedDescription);
	}
	else {
		DLog(@"Advertising started successfully");
	}
}

- (void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral {
	switch (peripheral.state) {
		case CBPeripheralManagerStatePoweredOn:
			[self setupService];
			break;
			
		default:
			DLog(@"CBPeripheralManager changed state %i", (int)(peripheral.state));
			break;
	}
}

- (void)peripheralManager:(CBPeripheralManager *)peripheral didAddService:(CBService *)service error:(NSError *)error {
	if (!error) {
		[self advertise];
	}
}

@end
