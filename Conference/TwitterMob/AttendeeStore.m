//
//  AttendeeStore.m
//  TwitterMob
//
//  Created by Aleksey Novicov on 12/20/13.
//  Copyright (c) 2013 Yodel Code LLC. All rights reserved.
//

#import "AttendeeStore.h"
#import "AttendeeRecord.h"

@implementation AttendeeStore

+ (AttendeeStore *)sharedStore {
	static dispatch_once_t predicate = 0;
	__strong static id _sharedObject = nil;
	
	dispatch_once(&predicate, ^{
		NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);

		if ([paths count] == 0) {
			_sharedObject = [[self alloc] init];
		}
		else {
			NSString *filename	= NSStringFromClass([AttendeeStore class]);
			NSString *storeFile	= [[paths firstObject] stringByAppendingPathComponent:filename];
			NSFileManager *fm	= [NSFileManager defaultManager];
			
			// If the file exists load it in
			if ([fm fileExistsAtPath:storeFile]) {
				_sharedObject = [NSKeyedUnarchiver unarchiveObjectWithFile:storeFile];
			}
			else {
				_sharedObject = [[self alloc] init];
			}
		}
	});
	
	return _sharedObject;
}

- (id)init {
	self = [super init];
	if (self) {
		self.records = [[NSMutableArray alloc] initWithCapacity:100];
	}
	return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
	self = [super init];
	if (self) {
		self.records = [aDecoder decodeObjectForKey:@"records"];
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
	[aCoder encodeObject:self.records forKey:@"records"];
}

- (BOOL)save {
	BOOL saved = NO;
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	
	if ([paths count] > 0) {
		
		// Save the data
		NSString *filename	= NSStringFromClass([AttendeeStore class]);
		NSString *storeFile = [[paths firstObject] stringByAppendingPathComponent:filename];
		saved				= [NSKeyedArchiver archiveRootObject:[AttendeeStore sharedStore] toFile:storeFile];
	}
	return saved;
}

- (AttendeeRecord *)attendRecordForTwitterID:(NSString *)twitterID {
	__block AttendeeRecord *record = nil;
	
	// Find an existing record by twitterID
	if (twitterID) {
		[self.records enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
			AttendeeRecord *currentRecord = obj;
			
			if ([currentRecord.twitterID isEqualToString:twitterID]) {
				record = currentRecord;
			}
		}];
	}
	
	// If no record found, create a new one
	if (!record) {
		record = [AttendeeRecord new];
		[self.records addObject:record];
	}
	return  record;
}

@end
