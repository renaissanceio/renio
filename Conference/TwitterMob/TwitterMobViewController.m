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
#import "TweeStartupView.h"

#define CIRCLE_DIAMETER	200
#define VERTICAL_BUFFER	0

// Make sure the AttendeeAdvertiser is retained always. Otherwise the
// Core Bluetooth characteristics we are advertising will not persist.

static AttendeeAdvertiser *advertiser;

@implementation TwitterMobViewController {
	UIView			*zoomView;
	CGFloat			initialVerticalOffset;
	NSString		*currentUsername;
	AttendeeBrowser	*browser;
	NSTimer			*refreshTimer;
}

+ (UINavigationController *)initialViewController {
	UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"TwitterMob" bundle:nil];
	UINavigationController *twitterMob = [storyboard instantiateInitialViewController];
	
	return twitterMob;
}

- (instancetype) initWithCoder:(NSCoder *)aDecoder {
	if (self = [super initWithCoder:aDecoder]) {
		self.tabBarItem.image = [UIImage imageNamed:@"Twitter.png"];
		
		self.tabBarItem.title = @"Twee";
	}
	return self;
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[self cancelRefreshTimer];
	[self updateStore:nil];
}

- (void)viewDidLoad {
	[super viewDidLoad];
	
	CGSize contentSize = CGSizeMake(self.view.frame.size.width, self.view.frame.size.height * 3);
	zoomView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, contentSize.width, contentSize.height)];
	zoomView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleHeight;
	
	[self.scrollView addSubview:zoomView];
		
	self.scrollView.contentSize				= contentSize;
	self.scrollView.minimumZoomScale		= 1.0;
	self.scrollView.maximumZoomScale		= 2.0;
	self.scrollView.delegate				= self;
	self.scrollView.directionalLockEnabled	= YES;
	
	self.versionLabel.text = [[[NSBundle mainBundle] infoDictionary] valueForKey:@"CFBundleShortVersionString"];
	
	[self startRefreshTimer];
	
	// Register for application events
	[[NSNotificationCenter defaultCenter] addObserver: self
											 selector: @selector(updateStore:)
												 name: UIApplicationDidEnterBackgroundNotification
											   object: nil];
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	
	TwitterStore *twitter = [TwitterStore sharedStore];
	
	// To prevent thrashing, restart only if the username has changed
	if (![currentUsername isEqualToString:twitter.username]) {
		currentUsername = twitter.username;

		[self removeAllAttendeeViews];
		
		if (twitter.username) {
			[self unloadTweeStartupView];
			[self startBrowsing];
		}
		else {
			[advertiser stop];
			[browser stop];
			
			advertiser = nil;
			browser = nil;
			
			[self loadTweeStartupView];
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
		
		if (firstAttendee.range > secondAttendee.range) {
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
	
	CGFloat frameHeight =self.self.view.frame.size.height;
	
	// Adjust the content size height so that we don't have any extra space
	if (verticalOffset < frameHeight) {
		verticalOffset = frameHeight + VERTICAL_BUFFER;
	}
	self.scrollView.contentSize = CGSizeMake(self.scrollView.contentSize.width, verticalOffset * self.scrollView.zoomScale);
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

#pragma mark - UIScrollViewDelegate

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return zoomView;
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView {
	self.versionLabel.hidden = (scrollView.zoomScale != 1.0);
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
	// Keep zoomView centered horizontally within scrollView
	CGFloat xOffset = scrollView.bounds.size.width/2 + scrollView.contentOffset.x;

	CGPoint newCenter = CGPointMake(xOffset, zoomView.center.y);
	zoomView.center = newCenter;
}

#pragma mark - TwitterStore

- (void)loadTwitterAccounts {
	[[TwitterStore sharedStore] fetchTwitterAccountsWithBlock:^(BOOL granted, NSArray *accounts) {
		
		dispatch_async(dispatch_get_main_queue(), ^{
			
			if (granted && accounts.count > 0) {
				[self performSegueWithIdentifier:@"TwitterAccountSegue" sender:nil];
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

#pragma mark - TweeStartupView

- (IBAction)startNowAction:(id)sender {
	[self loadTwitterAccounts];
}

- (void)loadTweeStartupView {
	if (!self.tweeStartupView) {
		// Storyboards do not load views from NIB files. So we have to do it manually
		UINib *nib = [UINib nibWithNibName:@"TweeStartupView" bundle:nil];
		[nib instantiateWithOwner:self options:nil];
		
		// Resize width take take advantage of full screen width
		CGRect newFrame = self.scrollView.bounds;
		newFrame.size.height = self.tweeStartupView.bounds.size.height;
		self.tweeStartupView.frame = newFrame;
		
		[self.scrollView addSubview:self.tweeStartupView];
		
		// Oversize just in case
		self.scrollView.contentSize = CGSizeMake(self.view.bounds.size.width, self.tweeStartupView.bounds.size.height) ;
		self.scrollView.backgroundColor = [UIColor darkGrayColor];
	}
}

- (void)unloadTweeStartupView {
	[self.tweeStartupView removeFromSuperview];
	self.tweeStartupView = nil;
	
	// The default background color when Twee is up and running
	self.scrollView.backgroundColor = [UIColor lightGrayColor];
}

@end
