//
//  TwitterHistoryViewController.m
//  TwitterMob
//
//  Created by Aleksey Novicov on 12/21/13.
//  Copyright (c) 2013 Yodel Code LLC. All rights reserved.
//

#import "TwitterHistoryViewController.h"
#import "AttendeeStore.h"
#import "AttendeeRecord.h"

@implementation TwitterHistoryViewController {
	NSArray *sortedAttendeeRecords;
}

- (void)viewDidLoad {
    [super viewDidLoad];
	
	// Sort the attendee records by score
	sortedAttendeeRecords = [[AttendeeStore sharedStore].records sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
		
		AttendeeRecord *firstRecord = obj1;
		AttendeeRecord *secondRecord = obj2;
		
		if (firstRecord.score == secondRecord.score) {
			return NSOrderedSame;
		}
		
		if (firstRecord.score > secondRecord.score) {
			return NSOrderedAscending;
		}
		else {
			return NSOrderedDescending;
		}
	}];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return sortedAttendeeRecords.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"AttendeeHistoryCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    AttendeeRecord *record		= [sortedAttendeeRecords objectAtIndex:indexPath.row];
	cell.textLabel.text			= record.twitterID;
	cell.detailTextLabel.text	= [[NSNumber numberWithInteger:record.score] stringValue];
    
    return cell;
}

@end
