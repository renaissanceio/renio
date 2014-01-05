//
//  AttendeeStore.h
//  TwitterMob
//
//  Created by Aleksey Novicov on 12/20/13.
//  Copyright (c) 2013 Yodel Code LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@class AttendeeRecord;

@interface AttendeeStore : NSObject <NSCoding>

@property (nonatomic, strong) NSMutableArray *records;

+ (AttendeeStore *)sharedStore;
- (AttendeeRecord *)attendRecordForTwitterID:(NSString *)twitterID;
- (BOOL)save;

@end
