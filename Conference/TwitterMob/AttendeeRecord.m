//
//  AttendeeRecord.m
//  TwitterMob
//
//  Created by Aleksey Novicov on 12/21/13.
//  Copyright (c) 2013 Yodel Code LLC. All rights reserved.
//

#import "AttendeeRecord.h"


@implementation AttendeeRecord

- (id)initWithCoder:(NSCoder *)aDecoder {
	self = [super init];
	if (self) {
		self.lastUpdatedDate	= [aDecoder decodeObjectForKey:@"lastUpdatedDate"];
		self.twitterID			= [aDecoder decodeObjectForKey:@"twitterID"];
		self.score				= [aDecoder decodeIntegerForKey:@"score"];
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
	[aCoder encodeObject:self.lastUpdatedDate forKey:@"lastUpdatedDate"];
	[aCoder encodeObject:self.twitterID forKey:@"twitterID"];
	[aCoder encodeInteger:self.score forKey:@"score"];
}

- (void)incrementScoreByAmount:(NSUInteger)amount {
	// Increment the score if the last updated date has either never been
	// set, or if at least 1 minute has transpired since last being set.
	
	if (!self.lastUpdatedDate || [self.lastUpdatedDate timeIntervalSinceNow] < -60) {
		self.score += amount;
	}
}

- (void)setScore:(NSInteger)score {
	_score = score;
	
	self.lastUpdatedDate = [NSDate date];
}

@end
