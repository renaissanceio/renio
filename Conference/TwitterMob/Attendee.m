//
//  Attendee.m
//  TwitterMob
//
//  Created by Aleksey Novicov on 12/5/13.
//  Copyright (c) 2013 Yodel Code LLC. All rights reserved.
//

#import "Attendee.h"
#import "NSString+HashColor.h"

#define DEFAULT_FAR_RSSI	-120
#define UNREALISTIC_RSSI	-15
#define TIMEOUT_PERIOD		8.0


@implementation Attendee {
	NSDate *lastSeenDate;
}

- (id)init {
	self = [super init];
	
	if (self) {
		// Set the default RSSI as very far away
		self.RSSI = [NSNumber numberWithInteger:DEFAULT_FAR_RSSI];
		self.age = 0;
	}
	return self;
}

- (void)dealloc {
	[self.timer invalidate];
}

- (BOOL)matchesAttendee:(Attendee *)attendee {
	return [self.peripheral.identifier isEqual:attendee.peripheral.identifier];
}

- (UIColor *)fillColor {
	if (self.twitterID) {
		return [self.twitterID hashColor];
	}
	return [UIColor darkGrayColor];
}

- (void)setRSSI:(NSNumber *)RSSI {
	// Ignore unrealistic spikes in RSSI value
	if ([RSSI integerValue] < UNREALISTIC_RSSI) {
		_RSSI = RSSI;
		
		AttendeeRange previousRange = self.range;
		
		NSInteger rssi = [self.RSSI integerValue];
		
		if (rssi > -50) {
			_range = AttendeeRangeVeryClose;
		}
		else if (rssi > -60) {
			_range = AttendeeRangeClose;
		}
		else if (rssi > -70) {
			_range = AttendeeRangeNearby;
		}
		else if (rssi > -80) {
			_range = AttendeeRangeFar;
		}
		else {
			_range = AttendeeRangeVeryFar;
		}
		
		if (_range != previousRange) {
			if ([self.delegate respondsToSelector:@selector(attendeeRangeChanged:)])
				[self.delegate attendeeRangeChanged:self];
		}
	}
}

- (BOOL)isConnected {
	return (self.peripheral.state == CBPeripheralStateConnecting) || (self.peripheral.state == CBPeripheralStateConnected);
}

- (NSTimeInterval)age {
	return -[lastSeenDate timeIntervalSinceNow];
}

- (void)setAge:(NSTimeInterval)age {
	lastSeenDate = [NSDate dateWithTimeIntervalSinceNow:-age];
}

#pragma mark - Timer

- (void)startTimer {
	[self.timer invalidate];
	
	self.timer = [NSTimer scheduledTimerWithTimeInterval: TIMEOUT_PERIOD
												  target: self
												selector: @selector(timerFired:)
												userInfo: nil
												 repeats: NO];
}

- (void)cancelTimer {
	[self.timer invalidate];
	
	self.timer = nil;
}

- (void)timerFired:(NSTimer *)timer {
	if ([self.delegate respondsToSelector:@selector(attendeeTimeoutExpired:)]) {
		[self.delegate attendeeTimeoutExpired:self];
	}
	self.timer = nil;
}

@end

