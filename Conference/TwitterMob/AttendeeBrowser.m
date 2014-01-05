//
//  AttendeeBrowser.m
//  TwitterMob
//
//  Created by Aleksey Novicov on 12/17/13.
//  Copyright (c) 2013 Yodel Code LLC. All rights reserved.
//

#import "AttendeeBrowser.h"
#import "AttendeeAdvertiser.h"

#define MISSING_ATTENDEE_AGE	8.0

NSString * const PeripheralConnectionFailedNotification = @"PeripheralConnectionFailedNotification";

@interface AttendeeBrowser ()
@property (nonatomic, strong) NSMutableArray *attendees;
@end


@implementation AttendeeBrowser {
	CBCentralManager	*centralManager;
	BOOL				radioPoweredOn;
}

- (id)init {
	self = [super init];
	if (self) {
		centralManager	= [[CBCentralManager alloc] initWithDelegate:self queue:nil];
		_attendees		= [[NSMutableArray alloc] initWithCapacity:100];
	}
	return self;
}

- (void)stop {
	if (radioPoweredOn) {
		[centralManager stopScan];
		
		[self.attendees enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
			Attendee *attendee = obj;
			
			if (attendee.isConnected) {
				[centralManager cancelPeripheralConnection:attendee.peripheral];
			}
		}];
	}
	
	[self.attendees removeAllObjects];
	self.updated = YES;
}

- (void)start {
    [centralManager scanForPeripheralsWithServices:@[[CBUUID UUIDWithString:kAttendeeServiceUUIDString]]
										   options:@{ CBCentralManagerScanOptionAllowDuplicatesKey : @YES }];
}

- (Attendee *)attendeeForPeripheral:(CBPeripheral *)peripheral {
	__block Attendee *attendee = nil;
	
	[self.attendees enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
		Attendee *currentAttendee = obj;
		
		if ([currentAttendee.peripheral.identifier isEqual:peripheral.identifier]) {
			attendee = currentAttendee;
			*stop = YES;
		}
	}];
	
	return attendee;
}

- (void)removeAttendee:(Attendee *)attendee {
	if (attendee) {
		if (attendee.isConnected) {
			[centralManager cancelPeripheralConnection:attendee.peripheral];
		}
		
		[attendee cancelTimer];
		[self.attendees removeObject:attendee];
	}
}

- (void)removeAttendeeForPeripheral:(CBPeripheral *)peripheral {
	Attendee *attendee = [self attendeeForPeripheral:peripheral];
	[self removeAttendee:attendee];
}

- (BOOL)removeOldAttendees {
	NSMutableArray *missingAttendees = [[NSMutableArray alloc] initWithCapacity:self.attendees.count];
	
	[self.attendees enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
		Attendee *attendee = obj;
		
		if (attendee.age > MISSING_ATTENDEE_AGE) {
			[missingAttendees addObject:attendee];
		}
	}];
	
	if (missingAttendees.count > 0) {
		DLog(@"Removing %lu old attendee(s)", (unsigned long)missingAttendees.count);
		[self.attendees removeObjectsInArray:missingAttendees];
	}
	
	return (missingAttendees.count > 0);
}

#pragma mark - AttendeeDelegate

- (void)attendeeRangeChanged:(Attendee *)attendee {
	self.updated = YES;
}

- (void)attendeeTimeoutExpired:(Attendee *)attendee {
	[self removeAttendee:attendee];
	self.updated = YES;
}

#pragma mark - CBCentralManagerDelegate

- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
	switch (central.state) {
		case CBCentralManagerStatePoweredOn:
			radioPoweredOn = YES;
			
			[self start];
			break;
			
		case CBCentralManagerStatePoweredOff:
			radioPoweredOn = NO;
			
			[self stop];
			break;
			
		default: {
			DLog(@"CBCentralManager changed state %i", (int)(central.state));
			break;
		}
	}
}

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI {
	Attendee *attendee	= [self attendeeForPeripheral:peripheral];
	
	// Have we ever seen this peripheral?
	if (attendee) {
		attendee.RSSI = RSSI;
		attendee.age = 0;
	}
    else {
		DLog(@"Creating a new attendee...");
		
		Attendee *attendee	= [Attendee new];
		attendee.delegate	= self;
		
        // Save a local copy of the peripheral, so CoreBluetooth doesn't get rid of it.
		[self.attendees addObject:attendee];
		
		attendee.peripheral	= peripheral;
		attendee.RSSI		= RSSI;
		
		// Initiate connection
		[centralManager connectPeripheral:peripheral options:nil];
		[attendee startTimer];
    }
}

- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    DLog(@"Failed to connect to %@. (%@)", peripheral.name, [error localizedDescription]);
	[self removeAttendeeForPeripheral:peripheral];

	[[NSNotificationCenter defaultCenter] postNotificationName:PeripheralConnectionFailedNotification object:peripheral];
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
    DLog(@"Peripheral %@ connected", peripheral.name);
	
	peripheral.delegate = self;
	[peripheral discoverServices:@[[CBUUID UUIDWithString:kAttendeeServiceUUIDString]]];
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    DLog(@"Peripheral %@ disconnected: %@", peripheral.name, error.localizedDescription);

	Attendee *attendee	= [self attendeeForPeripheral:peripheral];
	
	if (attendee && !attendee.twitterID) {
		// We disconnected before reading the twitterID, Release the attendee so we can start over
		
		[attendee cancelTimer];
		[self.attendees removeObject:attendee];
	}
}

#pragma mark - CBPeripheralDelegate

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error {
    if (error) {
		DLog(@"Error discovering services: %@", error.localizedDescription);
		[self removeAttendeeForPeripheral:peripheral];
    }
	else {
		DLog(@"Discovering characteristics...");
		
		// Discover the characteristic we want...
		CBUUID *twitterCBUUID = [CBUUID UUIDWithString:kCharacteristicTwitterIDUUIDString];
		
		// Loop through the newly filled peripheral.services array, just in case there's more than one.
		for (CBService *service in peripheral.services) {
			[peripheral discoverCharacteristics:@[twitterCBUUID] forService:service];
		}
	}
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error {
    if (error) {
		DLog(@"Error discovering characteristics: %@", error.localizedDescription);
		[self removeAttendeeForPeripheral:peripheral];
	}
	else {
		// Loop through the array just in case there happen to be multiple services
		for (CBCharacteristic *characteristic in service.characteristics) {
			
			// And check if it's the right one
			if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:kCharacteristicTwitterIDUUIDString]]) {
				
				DLog(@"Reading characteristic...");
				[peripheral readValueForCharacteristic:characteristic];
			}
		}
	}
}

- (void)peripheral:(CBPeripheral *)peripheral didModifyServices:(NSArray *)invalidatedServices {
	DLog(@"Invalidated services for %@. Canceling peripheral connection.", peripheral.name);
	[self removeAttendeeForPeripheral:peripheral];
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    if (error) {
		DLog(@"Error updating characteristics: %@", error.localizedDescription);
		[self removeAttendeeForPeripheral:peripheral];
    }
	else {
		Attendee *attendee	= [self attendeeForPeripheral:peripheral];
		
		if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:kCharacteristicTwitterIDUUIDString]]) {
			NSString *stringFromData = [[NSString alloc] initWithData:characteristic.value encoding:NSUTF8StringEncoding];
			attendee.twitterID = stringFromData;
			
			DLog(@"New twitterID: %@", attendee.twitterID);
			[centralManager cancelPeripheralConnection:peripheral];
			
			[attendee cancelTimer];
			self.updated = YES;
		}
	}
}

@end
