//
//  RadTableViewCell.h
//  #renio
//
//  Created by Tim Burks on 11/9/13.
//  Copyright (c) 2013 Radtastical Inc. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
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
