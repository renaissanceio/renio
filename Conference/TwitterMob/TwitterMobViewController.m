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
#import "RadStyleManager.h"

#define CIRCLE_DIAMETER	200
#define VERTICAL_BUFFER	0

// Make sure the AttendeeAdvertiser is retained always. Otherwise the
// Core Bluetooth characteristics we are advertising will not persist.

static AttendeeAdvertiser *advertiser;

@interface TwitterMobViewController ()
@property (nonatomic, strong) UITableViewCell *trackingCell;
@property (strong, nonatomic) UILabel *versionLabel;
@property (strong, nonatomic) UILabel *noDevicesLabel;
@end

@implementation TwitterMobViewController {
	UIView			*activityView;
	CGFloat			initialVerticalOffset;
	NSString		*currentUsername;
	AttendeeBrowser	*browser;
	NSTimer			*refreshTimer;
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
    
    activityView = [[UIView alloc] initWithFrame:self.trackingCell.contentView.bounds];
	activityView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	[self.trackingCell.contentView addSubview:activityView];
    
    CGRect noDevicesLabelFrame = activityView.bounds;
    noDevicesLabelFrame.size.height = 40 * [[RadStyleManager sharedInstance] deviceTextScale];
    self.noDevicesLabel = [[UILabel alloc] initWithFrame:noDevicesLabelFrame];
    self.noDevicesLabel.backgroundColor = [UIColor whiteColor];
    self.noDevicesLabel.text = @"Scanning for devices...";
    self.noDevicesLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    self.noDevicesLabel.textAlignment = NSTextAlignmentCenter;
    self.noDevicesLabel.font = [UIFont fontWithName:@"AvenirNext-Medium" size:16*[[RadStyleManager sharedInstance] deviceTextScale]];
    [activityView addSubview:self.noDevicesLabel];
    
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
    [self updateStore:nil];
    [self loadTwitterAccounts];
}

- (void) presentHistoryViewController
{
    [self updateStore:nil];
    TwitterHistoryViewController *controller = [[TwitterHistoryViewController alloc] init];
    RadNavigationController *navigationController = [[RadNavigationController alloc] initWithRootViewController:controller];
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

#pragma mark - AttendeeViews

- (AttendeeView *)attendeeViewForAttendee:(Attendee *)attendee {
	__block AttendeeView *attendeeViewForAttendee;
	
	[activityView.subviews enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if ([obj isKindOfClass:[AttendeeView class]]) {
            AttendeeView *attendeeView = obj;
            
            if ([attendeeView.attendee matchesAttendee:attendee]) {
                attendeeViewForAttendee = attendeeView;
                *stop = YES;
            }
        }
	}];
	
	return attendeeViewForAttendee;
}

- (AttendeeView *)freshAttendeeView {
	AttendeeView *attendeeView	= [[AttendeeView alloc] initWithFrame:CGRectMake(0, 0, CIRCLE_DIAMETER, CIRCLE_DIAMETER)];
	attendeeView.center			= CGPointMake(activityView.bounds.size.width/2, self.view.bounds.size.height);
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
    
    self.noDevicesLabel.hidden = ([sortedAttendees count] > 0);
    
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
			
			[activityView addSubview:attendeeView];
		}
		
		// Set position of the AttendeeView
		[UIView animateWithDuration:0.5 animations:^{
			verticalOffset += attendeeView.frame.size.height/2;
			attendeeView.center = CGPointMake(activityView.bounds.size.width/2, verticalOffset);
			
			// Setup vertical offset for next AttendeeView
			verticalOffset += attendeeView.frame.size.height/2 + VERTICAL_BUFFER;
		}];
	}];
	
	CGFloat frameHeight = self.view.bounds.size.height - 64 /* top */ - 44 /* bottom */;
	
	// Adjust the content size height so that we don't have any extra space
	if (verticalOffset < frameHeight) {
		verticalOffset = frameHeight + VERTICAL_BUFFER;
	}
    
    // we have a table containing a single cell with height = verticalOffset
    CGRect zoomFrame = self->activityView.frame;
    zoomFrame.size.height = verticalOffset;
    self->activityView.frame = zoomFrame;
    
    [self.tableView reloadData];
}

- (void)removeAllAttendeeViews {
	[activityView.subviews enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if ([obj isKindOfClass:[AttendeeView class]]) {
            [obj removeFromSuperview];
        }
	}];
}

- (void)removeOldAttendeeViews {
	[activityView.subviews enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if ([obj isKindOfClass:[AttendeeView class]]) {
            AttendeeView *attendeeView = obj;
            
            BOOL attendeeExists = [browser.attendees containsObject:attendeeView.attendee];
            
            if (!attendeeExists) {
                [attendeeView removeFromSuperview];
            }
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
        return self->activityView.bounds.size.height;
    } else {
        return [super tableView:tableView heightForRowAtIndexPath:indexPath];
    }
}

#pragma mark - TwitterStore

- (void)loadTwitterAccounts {
	[[TwitterStore sharedStore] fetchTwitterAccountsWithBlock:^(BOOL granted, NSArray *accounts) {
		dispatch_async(dispatch_get_main_queue(), ^{
			if (granted && accounts.count > 0) {
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
	NSString *instructions = @"Please go to Settings, select Twitter, and login to your Twitter account. You may also need to change a switch to allow this app to access your Twitter account information.";
	UIAlertView *alertView = [[UIAlertView alloc] initWithTitle: @"No Twitter Accounts"
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
