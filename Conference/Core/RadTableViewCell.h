//
//  RadTableViewCell.h
//  #renio
//
//  Created by Tim Burks on 11/9/13.
//  Copyright (c) 2013 Radtastical Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "RadTableViewController.h"

@interface RadTableViewCell : UITableViewCell

@property (nonatomic, weak) RadTableViewController *controller;
@property (nonatomic, strong) NSIndexPath *indexPath;
@property (nonatomic, strong) id contents;
@property (nonatomic, strong) MKMapView *mapView;
@property (nonatomic, strong) RadSlider *slider;
@property (nonatomic, strong) RadTextView *textView;
@property (nonatomic, strong) RadTextField *textField;
@property (nonatomic, strong) UILabel *rightSideLabel;

- (void) resetWithIndexPath:(NSIndexPath *) indexPath controller:(RadTableViewController *) controller;

@end
