//
//  NSString+HashColor.m
//  TwitterMob
//
//  Created by Aleksey Novicov on 12/18/13.
//  Copyright (c) 2013 Yodel Code LLC. All rights reserved.
//
// Returns a color representation of the NSString. Updated daily.

#import "NSString+HashColor.h"
#import "NSString+MD5.h"

#define COLOR_LIMIT	0.8

@implementation NSString (HashColor)

- (NSString *)todayDateString {
	static NSDateFormatter *dateFormatter;
	if (!dateFormatter) {
		dateFormatter = [[NSDateFormatter alloc] init];
		[dateFormatter setDateStyle:NSDateFormatterShortStyle];
		[dateFormatter setTimeStyle:NSDateFormatterNoStyle];
	}
	return [dateFormatter stringFromDate:[NSDate date]];
}

- (UIColor *)hashColor {
	// Return a color that is a hash of the username and current date
	NSString *hash = [[NSString stringWithFormat:@"%@%@", self, [self todayDateString]] MD5];
	
	unsigned int colorValue;
	NSScanner *scanner = [NSScanner scannerWithString:[hash substringToIndex:6]];
	
	if ([scanner scanHexInt:&colorValue]) {
		NSInteger blue	= (colorValue)       & 0xFF;
		NSInteger green = (colorValue >>  8) & 0xFF;
		NSInteger red	= (colorValue >> 16) & 0xFF;
		
		CGFloat redValue	= red/256.0;
		CGFloat greenValue	= green/256.0;
		CGFloat blueValue	= blue/256.0;
		
		// Stay away from super light colors
		if (redValue > COLOR_LIMIT && greenValue > COLOR_LIMIT && blueValue > COLOR_LIMIT) {
			if (redValue > COLOR_LIMIT) {
				redValue  -= (1.0 - COLOR_LIMIT);
			}
			else if (greenValue > COLOR_LIMIT) {
				greenValue  -= (1.0 - COLOR_LIMIT);
			}
			else if (blueValue > COLOR_LIMIT) {
				blueValue  -= (1.0 - COLOR_LIMIT);
			}
		}
		return [UIColor colorWithRed:redValue green:greenValue blue:blueValue alpha:1.0];
	}
	else {
		return [UIColor colorWithRed:0.9 green:0.9 blue:0.9 alpha:1.0];
	}
}

@end
