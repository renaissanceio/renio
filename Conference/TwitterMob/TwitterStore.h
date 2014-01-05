//
//  TwitterStore.h
//  TwitterMob
//
//  Created by Aleksey Novicov on 6/3/12.
//  Copyright (c) 2012 Yodel Code LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Accounts/Accounts.h>

@interface TwitterStore : NSObject

@property (nonatomic, strong) NSString *username;
@property (nonatomic, readonly) NSArray *accounts;
@property (nonatomic, readonly) BOOL hasAccounts;

+ (TwitterStore *)sharedStore;
- (void)fetchTwitterAccountsWithBlock:(void (^)(BOOL granted, NSArray *accounts))block;

@end
