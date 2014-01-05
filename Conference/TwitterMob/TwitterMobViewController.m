//
//  TwitterMobViewController.m
//  TwitterMob
//
//  Created by Aleksey Novicov on 11/23/13.
//  Copyright (c) 2013 Yodel Code LLC. All rights reserved.
//

#import "TwitterMobViewController.h"
#import "TwitterStore.h"
#import "Attendee.h"
#import "AttendeeView.h"
#import "AttendeeAdvertiser.h"
#import "AttendeeBrowser.h"
#import "AttendeeStore.h"
#import "AttendeeRecord.h"

#import "TwitterAccountViewController.h"
#import "TwitterHistoryViewController.h"
#import "RadNavigationController.h"

#define CIRCLE_DIAMETER	200
#define VERTICAL_BUFFER	0

// Make sure the AttendeeAdvertiser is retained always. Otherwise the
// Core Bluetooth characteristics we are advertising will not persist.

static AttendeeAdvertiser *advertiser;

@interface TwitterMobViewController ()
@property (nonatomic, strong) UITableViewCell *trackingCell;
@property (strong, nonatomic) UILabel *versionLabel;
@end

@implementation TwitterMobViewController {
	UIView			*zoomView;
	CGFloat			initialVerticalOffset;
	NSString		*currentUsername;
	AttendeeBrowser	*browser;
	NSTimer			*refreshTimer;
    CGFloat         viewHeight;
    BOOL            tracking;
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[self cancelRefreshTimer];
	[self updateStore:nil];
}

- (void)viewDidLoad {
	[super viewDidLoad];
	
    self.trackingCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Track"];
    self.trackingCell.selectionStyle = UITableViewCellSelectionStyleNone;
    //self.trackingCell.backgroundColor = [UIColor colorWithWhite:0.9 alpha:1.0];

	CGSize contentSize = CGSizeMake(self.view.frame.size.width, self.view.frame.size.height);
	zoomView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, contentSize.width, 3*contentSize.height)];
	zoomView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    //zoomView.backgroundColor = [UIColor darkGrayColor];
	self->viewHeight = zoomView.bounds.size.height;
	[self.trackingCell.contentView addSubview:zoomView];
    
	self.versionLabel.text = [[[NSBundle mainBundle] infoDictionary] valueForKey:@"CFBundleShortVersionString"];
	
	[self startRefreshTimer];
	
	// Register for application events
	[[NSNotificationCenter defaultCenter] addObserver: self
											 selector: @selector(updateStore:)
												 name: UIApplicationDidEnterBackgroundNotification
											   object: nil];
}

- (void) presentAccountViewController
{
    [self loadTwitterAccounts];
}

- (void) presentHistoryViewController
{
    TwitterHistoryViewController *controller = [[TwitterHistoryViewController alloc] init];
    RadNavigationController *navigationController = [[RadNavigationController alloc]
                                                     initWithRootViewController:controller];
    [self presentViewController:navigationController animated:YES completion:NULL];
}


- (void) viewWillAppear:(BOOL)animated {
    
    [super viewWillAppear:animated];
	TwitterStore *twitter = [TwitterStore sharedStore];
	
	// To prevent thrashing, restart only if the username has changed
	if (![currentUsername isEqualToString:twitter.username]) {
		currentUsername = twitter.username;
        
		[self removeAllAttendeeViews];
		
		if (twitter.username) {
			[self startBrowsing];
            self->tracking = YES;
            [self.tableView reloadData];
		}
		else {
			[advertiser stop];
			[browser stop];
			
			advertiser = nil;
			browser = nil;
			
            self->tracking = NO;
            [self.tableView reloadData];
		}
	}
	else {
		// Fixes the layout bug when we return
		[self update];
	}
}

#pragma mark - Segues

- (BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender {
	BOOL shouldPerform = YES;
	
	if ([identifier isEqualToString:@"TwitterAccountSegue"]) {
		shouldPerform = [TwitterStore sharedStore].hasAccounts;
		
		if (!shouldPerform) {
			[self loadTwitterAccounts];
		}
	}
	return shouldPerform;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
	// For any segue, update the AttendStore
	[self updateStore:nil];
}

#pragma mark - AttendeeViews

- (AttendeeView *)attendeeViewForAttendee:(Attendee *)attendee {
	__block AttendeeView *attendeeViewForAttendee;
	
	[zoomView.subviews enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
		AttendeeView *attendeeView = obj;
		
		if ([attendeeView.attendee matchesAttendee:attendee]) {
			attendeeViewForAttendee = attendeeView;
			*stop = YES;
		}
	}];
	
	return attendeeViewForAttendee;
}

- (AttendeeView *)freshAttendeeView {
	AttendeeView *attendeeView	= [[AttendeeView alloc] initWithFrame:CGRectMake(0, 0, CIRCLE_DIAMETER, CIRCLE_DIAMETER)];
	attendeeView.center			= CGPointMake(zoomView.bounds.size.width/2, self.view.bounds.size.height);
	attendeeView.pulseEnabled	= YES;
	
	return attendeeView;
}

- (void)update {
	__block CGFloat verticalOffset = initialVerticalOffset + VERTICAL_BUFFER;
	
	// Get a sorted array of attendees, by range
	NSArray *sortedAttendees = [browser.attendees sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
		Attendee *firstAttendee = obj1;
		Attendee *secondAttendee = obj2;
		
		if (firstAttendee.range == secondAttendee.range) {
			return NSOrderedSame;
		}
        else if (firstAttendee.range > secondAttendee.range) {
			return NSOrderedAscending;
		}
		else {
			return NSOrderedDescending;
		}
	}];
	
	[self removeOldAttendeeViews];
	
	// Update the associated AttendeeViews for each Attendee
	[sortedAttendees enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
		Attendee *attendee = obj;
		AttendeeView *attendeeView = [self attendeeViewForAttendee:attendee];
		
		if (attendeeView) {
			// Update the size, color, and name of the circle
			[attendeeView update];
		}
		else {
			// Create a new AttendeeView if one can't be found
			attendeeView = [self freshAttendeeView];
			attendeeView.attendee = attendee;
			
			[zoomView addSubview:attendeeView];
		}
		
		// Set position of the AttendeeView
		[UIView animateWithDuration:0.5 animations:^{
			verticalOffset += attendeeView.frame.size.height/2;
			attendeeView.center = CGPointMake(zoomView.bounds.size.width/2, verticalOffset);
			
			// Setup vertical offset for next AttendeeView
			verticalOffset += attendeeView.frame.size.height/2 + VERTICAL_BUFFER;
		}];
	}];
	
	CGFloat frameHeight = self.view.frame.size.height;
	
	// Adjust the content size height so that we don't have any extra space
	if (verticalOffset < frameHeight) {
		verticalOffset = frameHeight + VERTICAL_BUFFER;
	}
    
    // we have a table containing a single cell with height = self->viewHeight
    //self->viewHeight = verticalOffset;
    //[self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0]]
    //                      withRowAnimation:UITableViewRowAnimationNone];
    
    //UIScrollView *scrollView = (UIScrollView *) self.view;
	//scrollView.contentSize = CGSizeMake(scrollView.contentSize.width, verticalOffset * scrollView.zoomScale);
}

- (void)removeAllAttendeeViews {
	[zoomView.subviews enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
		[obj removeFromSuperview];
	}];
}

- (void)removeOldAttendeeViews {
	[zoomView.subviews enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
		AttendeeView *attendeeView = obj;
		
		BOOL attendeeExists = [browser.attendees containsObject:attendeeView.attendee];
		
		if (!attendeeExists) {
			[attendeeView removeFromSuperview];
		}
	}];
}

#pragma mark - AttendeeBrowser

- (void)startBrowsing {
	NSString *username = [TwitterStore sharedStore].username;
	
	if (username) {
		browser = [[AttendeeBrowser alloc] init];
		advertiser = [[AttendeeAdvertiser alloc] initWithTwitterID:username];
	}
}

#pragma mark - Timer

- (void)startRefreshTimer {
	[refreshTimer invalidate];
	
	refreshTimer = [NSTimer scheduledTimerWithTimeInterval: 2.0
													target: self
												  selector: @selector(timerFired:)
												  userInfo: nil
												   repeats: YES];
}

- (void)cancelRefreshTimer {
	[refreshTimer invalidate];
	refreshTimer = nil;
}

- (void)timerFired:(NSTimer *)timer {
	BOOL browserUpdated = browser.updated;
	BOOL oldAttendeesRemoved = [browser removeOldAttendees];
	
	// We need to reset the flag
	browser.updated = NO;
	
	if (browserUpdated || oldAttendeesRemoved) {
		[self update];
	}
}

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    if (tracking) {
        return 1;
    } else {
        return [super numberOfSectionsInTableView:tableView];
    }
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (tracking) {
        return 1;
    } else {
        return [super tableView:tableView numberOfRowsInSection:section];
    }
}

- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (tracking) {
        return self.trackingCell;
    } else {
        return [super tableView:tableView cellForRowAtIndexPath:indexPath];
    }
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (tracking) {
        NSLog(@"returning row height %f", self->viewHeight);
        return self->viewHeight;
        // return self->zoomView.bounds.size.height;
    } else {
        return [super tableView:tableView heightForRowAtIndexPath:indexPath];
    }
}

#pragma mark - TwitterStore

- (void)loadTwitterAccounts {
	[[TwitterStore sharedStore] fetchTwitterAccountsWithBlock:^(BOOL granted, NSArray *accounts) {
		
		dispatch_async(dispatch_get_main_queue(), ^{
			
			if (granted && accounts.count > 0) {
				// [self performSegueWithIdentifier:@"TwitterAccountSegue" sender:nil];
                TwitterAccountViewController *controller = [[TwitterAccountViewController alloc] init];
                RadNavigationController *navigationController = [[RadNavigationController alloc]
                                                                 initWithRootViewController:controller];
                [self presentViewController:navigationController animated:YES completion:NULL];
			}
			else {
				[self showTwitterAccountMissing];
			}
		});
	}];
}

- (void)showTwitterAccountMissing {
	NSString *instructions = @"Please go to Settings, select Twitter, and login to your Twitter account.";
	
	UIAlertView *alertView = [[UIAlertView alloc] initWithTitle: @"Twitter Account Missing"
														message: instructions
													   delegate: nil
											  cancelButtonTitle: @"Continue"
											  otherButtonTitles: nil];
	[alertView show];
}

#pragma mark - Data store

- (void)updateStore:(NSNotification *)note {
	
	[browser.attendees enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
		Attendee *currentAttendee = obj;
        
		if (currentAttendee.twitterID) {
			AttendeeRecord *record = [[AttendeeStore sharedStore] attendRecordForTwitterID:currentAttendee.twitterID];
			
			// Save the twitterID again just in case it's a new record
			record.twitterID = currentAttendee.twitterID;
			
			// The closer the attendee, the higher the score
			[record incrementScoreByAmount:currentAttendee.range];
		}
	}];
	
	BOOL saved = [[AttendeeStore sharedStore] save];
	
	if (!saved) {
		DLog(@"AttendeeStore could not be saved!");
	}
}

@end
