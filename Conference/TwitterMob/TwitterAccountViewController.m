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

- (instancetype) init
{
    if (self = [super init]) {
        NSMutableArray *rows = [NSMutableArray array];
        
        TwitterStore *twitter = [TwitterStore sharedStore];
        for (int i = 0; i < [twitter.accounts count]; i++) {
            ACAccount *account = [twitter.accounts objectAtIndex:i];
            NSString *twitterUsername = [@"@" stringByAppendingString:account.username];
            BOOL isSelected = [twitterUsername isEqualToString:twitter.username];
            if (isSelected) {
                selectedIndexPath = [NSIndexPath indexPathForRow:i inSection:1];
            }
            [rows addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:
                             twitterUsername, @"markdown",
                             isSelected ? @"checkmark" : @"none", @"accessory",
                             nil]];
        }
        
        self.contents = @{@"title":@"Accounts",
                          @"button_topright":@{@"text":@"Done",
                                               @"action":^(){[self dismissViewControllerAnimated:YES completion:NULL];}},
                          @"sections":@[
                                  @{@"rows":@[@{@"markdown":@"The Twitter username you select will be publicly shared over Bluetooth.\n\n\n\nPlease select a username to enable sharing. Deselecting a username disables sharing.",
                                              @"attributes":@"spaced"}]},
                                  @{@"rows":rows}
                                  ]};
    }
    return self;
}


#pragma mark - Table view data source

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([indexPath section] == 0) {
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
        return;
    }
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
