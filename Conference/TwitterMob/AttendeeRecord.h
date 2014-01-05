//
//  AttendeeRecord.h
//  TwitterMob
//
//  Created by Aleksey Novicov on 12/21/13.
//  Copyright (c) 2013 Yodel Code LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AttendeeRecord : NSObject <NSCoding>

@property (nonatomic, strong) NSDate *lastUpdatedDate;
@property (nonatomic, strong) NSString *twitterID;
@property (nonatomic, assign) NSInteger score;

- (void)incrementScoreByAmount:(NSUInteger)amount;

@end
