//
//  TwitterStore.m
//  TwitterMob
//
//  Created by Aleksey Novicov on 6/3/12.
//  Copyright (c) 2012 Yodel Code LLC. All rights reserved.
//

#import <Social/Social.h>
#import "TwitterStore.h"


@interface TwitterStore ()

@property (nonatomic, strong) NSString *accountIdentifier;
@property (nonatomic, strong) NSMutableArray *tweetSigns;
@property (nonatomic, assign) NSUInteger initialCount;

@end


@implementation TwitterStore

+ (TwitterStore *)sharedStore {
	static dispatch_once_t predicate = 0;
	__strong static TwitterStore *_sharedObject = nil;
	
	dispatch_once(&predicate, ^{
		_sharedObject = [[self alloc] init];
	});
	
	return _sharedObject;
}

#pragma mark - Properties

- (NSString *)username {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	return [defaults stringForKey:@"TwitterUsername"];
}

- (void)setUsername:(NSString *)username {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults setObject:username forKey:@"TwitterUsername"];
	[NSUserDefaults resetStandardUserDefaults];
	
	// Save corresponding account identifier
	[_accounts enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
		ACAccount *account = obj;
		
		if ([account.username isEqualToString:[username substringFromIndex:1]]) {
			self.accountIdentifier = account.identifier;
		}
	}];
}

- (NSString *)accountIdentifier {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	return [defaults stringForKey:@"TwitterAccountIdentifier"];
}

- (void)setAccountIdentifier:(NSString *)accountIdentifier {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults setObject:accountIdentifier forKey:@"TwitterAccountIdentifier"];
	[NSUserDefaults resetStandardUserDefaults];
}

#pragma mark - Public Methods

- (void)fetchTwitterAccountsWithBlock:(void (^)(BOOL, NSArray *))block {
	ACAccountStore *accountStore = [[ACAccountStore alloc] init];
	ACAccountType *accountType	 = [accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
	
	// Request access from the user to access their Twitter account
	[accountStore requestAccessToAccountsWithType:accountType options:nil completion:^(BOOL granted, NSError *error) {

		 // Did user allow us access?
		 if (granted == YES) {
			 // Populate array with all available Twitter accounts
			 _accounts = [accountStore accountsWithAccountType:accountType];
			 _hasAccounts = (_accounts.count > 0);
			 
			 block(YES, _accounts);
		 }
		 else {
			 self.username	= nil;
			 _accounts		= nil;
			 _hasAccounts	= NO;
			 
			 block(NO, nil);
		 }
	 }];
}

@end
