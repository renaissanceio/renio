//
//  TwitterAccountViewController.m
//  TwitterMob
//
//  Created by Aleksey Novicov on 12/6/13.
//  Copyright (c) 2013 Yodel Code LLC. All rights reserved.
//

#import "TwitterAccountViewController.h"
#import "TwitterStore.h"

@interface TwitterAccountViewController ()
@property (nonatomic, strong) NSString *twitterIdentifer;
@end

@implementation TwitterAccountViewController {
	NSIndexPath *selectedIndexPath;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return ([TwitterStore sharedStore].accounts.count);
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"TwitterUsernameCell";
	
	TwitterStore *twitter = [TwitterStore sharedStore];
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
	
	ACAccount *account = [twitter.accounts objectAtIndex:indexPath.row];
	NSString *twitterUsername = [@"@" stringByAppendingString:account.username];

	BOOL isSelected = [twitterUsername isEqualToString:twitter.username];
	
    cell.textLabel.text = twitterUsername;
	cell.accessoryType = (isSelected) ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
	
	if (isSelected) {
		selectedIndexPath = indexPath;
	}
	
	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	TwitterStore *twitter = [TwitterStore sharedStore];

	if ([indexPath isEqual:selectedIndexPath]) {
		selectedIndexPath = nil;
		
		twitter.username = nil;
		[tableView cellForRowAtIndexPath:indexPath].accessoryType = UITableViewCellAccessoryNone;
	}
	else {
		if (selectedIndexPath) {
			[tableView cellForRowAtIndexPath:selectedIndexPath].accessoryType = UITableViewCellAccessoryNone;
		}
		selectedIndexPath = indexPath;
		
		ACAccount *selectedAccount = [twitter.accounts objectAtIndex:indexPath.row];
		NSString *twitterUsername = [@"@" stringByAppendingString:selectedAccount.username];

		twitter.username = twitterUsername;
		[tableView cellForRowAtIndexPath:selectedIndexPath].accessoryType = UITableViewCellAccessoryCheckmark;
	}
	
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (IBAction)enableAction:(id)sender {
	[self dismissViewControllerAnimated:YES completion:nil];
}

@end
