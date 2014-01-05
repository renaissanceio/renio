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
#import "RadStyleManager.h"

@implementation TwitterHistoryViewController

- (instancetype) init
{
    if (self = [super init]) {
        // Sort the attendee records by score
        NSArray *sortedAttendeeRecords = [[AttendeeStore sharedStore].records sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
            
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
        
        NSMutableArray *rows = [NSMutableArray array];
        
        NSDictionary *attributes = [[RadStyleManager sharedInstance] paragraphAttributesWithTabStops];
        
        for (int i = 0; i < [sortedAttendeeRecords count]; i++) {
            AttendeeRecord *record		= [sortedAttendeeRecords objectAtIndex:i];
            NSString *leftText			= record.twitterID;
            NSString *rightText         = [[NSNumber numberWithInteger:record.score] stringValue];
            NSAttributedString *attributedText =
            [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@\t%@",leftText,rightText]
                                            attributes:attributes];
            [rows addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:
                             attributedText, @"attributedText",
                             nil]];
        }
        
        self.contents = @{@"title":@"History",
                          @"button_topright":@{@"text":@"Done",
                                               @"action":
                                                   ^(){
                                                       [self dismissViewControllerAnimated:YES completion:NULL];
                                                   }},
                          @"sections":@[@{@"rows":rows}]};
    }
    return self;
}

@end
