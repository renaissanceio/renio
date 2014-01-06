//
//  RadTableViewController.m
//  #renio
//
//  Created by Tim Burks on 11/8/13.
//  Copyright (c) 2013 Radtastical Inc Inc. All rights reserved.
//

#import "RadTableViewController.h"
#import "RadTableViewCell.h"
#import "UIImage+Mask.h"
#import "Conference.h"
#import "RadStyleManager.h"
#import "RadWebViewController.h"
#import "RadTitleView.h"
#import "RadNavigationController.h"
#import "RadFormDataManager.h"
#import "RadRequest.h"
#import "RadRequestRouter.h"
#import "Nu.h"

@implementation RadTextField
@end

@implementation RadTextView
@end

@implementation RadSlider
@end

@interface RadTableViewController ()
@property (nonatomic, weak) RadTextView *activeTextView;
@property (nonatomic, weak) RadTextField *activeTextField;
@property (nonatomic, strong) NSMutableArray *rightBarButtonItemStack;
@property (nonatomic, strong) MPMoviePlayerViewController *player;
@end

@implementation RadTableViewController

- (instancetype) initWithParameterString:(NSString *) parameterString
{
    if (self = [super initWithStyle:UITableViewStylePlain]) {
        RadRequest *request = [[RadRequest alloc] initWithPath:parameterString];
        if ([[RadRequestRouter sharedRouter] routeAndHandleRequest:request]) {
            id page = [request result];
            self.contents = page;
        }
    }
    return self;
}

- (void) setContents:(NSDictionary *)contents
{
    _contents = contents;
    NSString *title = [contents objectForKey:@"title"];
    if (title) {
        self.title = title; // implicitly sets tabBarItem.title
    }
    NSString *imageName = [contents objectForKey:@"image"];
    if (imageName) {
        self.tabBarItem.image = [UIImage imageNamed:imageName];
    }
    NSString *separator = [contents objectForKey:@"separator"];
    if (separator) {
        if ([separator isEqualToString:@"none"]) {
            self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        }
    }
}

- (void)loadView
{
    [super loadView];
    
    id rowHeight = [self.contents objectForKey:@"row_height"];
    if (rowHeight) {
        self.tableView.rowHeight = [rowHeight integerValue];
    }
    
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc]
                                             initWithTitle:@""
                                             style:UIBarButtonItemStylePlain
                                             target:nil
                                             action:NULL];
    
    RadTitleView *container = [[RadTitleView alloc]
                               initWithFrame:CGRectMake(0,0,self.view.bounds.size.width,44)];
    [container setText:self.title];
    
    self.navigationItem.titleView = container;
    
}

- (void) topLeftButtonPressed:(id) sender
{
    id button_topleft = [self.contents objectForKey:@"button_topleft"];
    if (button_topleft) {
        [self handlePressedButtonWithDescription:button_topleft];
    }
}

- (void) topRightButtonPressed:(id) sender
{
    id button_topright = [self.contents objectForKey:@"button_topright"];
    if (button_topright) {
        [self handlePressedButtonWithDescription:button_topright];
    }
}

- (void) handlePressedButtonWithDescription:(id) buttonDescription
{
    NSString *action = [buttonDescription objectForKey:@"action"];
    if (!action) {
    } else if ([action isKindOfClass:[NSString class]]) {
        NSArray *parts = [action componentsSeparatedByString:@" "];
        if ([parts count] < 2) {
            return;
        }
        NSString *verb = [parts objectAtIndex:0];
        NSString *path = [parts objectAtIndex:1];
        
        if ([verb isEqualToString:@"modal"]) {
            id page = [[RadRequestRouter sharedRouter] pageForPath:path];
            if (page) {
                RadTableViewController *controller = [[RadTableViewController alloc] init];
                controller.contents = page;
                UINavigationController *navigationController =
                [[RadNavigationController alloc] initWithRootViewController:controller];
                navigationController.navigationBar.barTintColor =
                self.navigationController.navigationBar.barTintColor;
                navigationController.navigationBar.tintColor =
                self.navigationController.navigationBar.tintColor;
                [self presentViewController:navigationController animated:YES completion:NULL];
            }
        } else if ([verb isEqualToString:@"video"]) {
            NSURL *URL = [NSURL URLWithString:path];
            self.player = [[MPMoviePlayerViewController alloc] initWithContentURL:URL];
            [self.player.moviePlayer prepareToPlay];
            [self presentMoviePlayerViewControllerAnimated:self.player];
        }
        
        Class ControllerClass = NSClassFromString([parts objectAtIndex:1]);
        if (!ControllerClass) {
            return;
        }
        UIViewController *viewController = [[ControllerClass alloc] init];
        UINavigationController *navigationController =
        [[RadNavigationController alloc] initWithRootViewController:viewController];
        navigationController.navigationBar.barTintColor =
        self.navigationController.navigationBar.barTintColor;
        navigationController.navigationBar.tintColor =
        self.navigationController.navigationBar.tintColor;
        [self presentViewController:navigationController animated:YES completion:^{
            
        }];
    } else if ([action isKindOfClass:[NuBlock class]]) {
        NuCell *args = [[NuCell alloc] init];
        [args setCar:self];
        NuBlock *block = (NuBlock *) action;
        [block evalWithArguments:args context:nil];
    } else if (action) {
        void (^actionBlock)() = (id) action;
        actionBlock();
    }
}

- (void) refresh
{
    NuBlock *refresh = [self.contents objectForKey:@"refresh"];
    if (refresh && [refresh isKindOfClass:[NuBlock class]]) {
        NuCell *args = [[NuCell alloc] init];
        args.car = self;
        id result = [refresh evalWithArguments:args context:[[Nu sharedParser] context]];
        NSMutableDictionary *newContents = [self.contents mutableCopy];
        [newContents addEntriesFromDictionary:result];
        self.contents = newContents;
    }
    
    id button_topleft = [self.contents objectForKey:@"button_topleft"];
    if (button_topleft) {
        NSString *imageName = [button_topleft objectForKey:@"image"];
        NSString *logoName = [button_topleft objectForKey:@"logo"];
        if (logoName) {
            UIImage *image = [UIImage imageNamed:logoName];
            UIImageView *imageView = [[UIImageView alloc]
                                      initWithImage:image];
            CGFloat width = image.size.width/image.size.height*44;
            imageView.frame = CGRectMake(0,0,width,44);
            self.navigationItem.leftBarButtonItem =
            [[UIBarButtonItem alloc] initWithCustomView:imageView];
        } else if (imageName) {
            UIImage *image = [UIImage imageNamed:imageName];
            self.navigationItem.leftBarButtonItem =
            [[UIBarButtonItem alloc] initWithImage:image
                               landscapeImagePhone:image
                                             style:UIBarButtonItemStylePlain
                                            target:self
                                            action:@selector(topLeftButtonPressed:)];
        } else {
            NSString *title = [button_topleft objectForKey:@"text"];
            self.navigationItem.leftBarButtonItem =
            [[UIBarButtonItem alloc] initWithTitle:title
                                             style:UIBarButtonItemStylePlain
                                            target:self
                                            action:@selector(topLeftButtonPressed:)];
        }
    }
    
    id button_topright = [self.contents objectForKey:@"button_topright"];
    if (button_topright) {
        NSString *imageName = [button_topright objectForKey:@"image"];
        if (imageName) {
            UIImage *image = [UIImage imageNamed:imageName];
            self.navigationItem.rightBarButtonItem =
            [[UIBarButtonItem alloc] initWithImage:image
                               landscapeImagePhone:image
                                             style:UIBarButtonItemStylePlain
                                            target:self
                                            action:@selector(topRightButtonPressed:)];
        } else {
            NSString *title = [button_topright objectForKey:@"text"];
            self.navigationItem.rightBarButtonItem =
            [[UIBarButtonItem alloc] initWithTitle:title
                                             style:UIBarButtonItemStylePlain
                                            target:self
                                            action:@selector(topRightButtonPressed:)];
        }
    }
    
    [self.tableView reloadData];
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self refresh];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(fontSizeDidChange:)
                                                 name:@"FontSizeChanged"
                                               object:nil];
}

- (void) viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void) fontSizeDidChange:(id) sender
{
    [self.tableView reloadData];
}

- (void) push:(UIViewController *) viewController
{
    [self.navigationController pushViewController:viewController
                                         animated:YES];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [[self.contents objectForKey:@"sections"] count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSMutableArray *rows = [[[self.contents objectForKey:@"sections"] objectAtIndex:section] objectForKey:@"rows"];
    return [rows count];
}

- (NSDictionary *) rowForIndexPath:(NSIndexPath *) indexPath
{
    NSMutableArray *rows = [[[self.contents objectForKey:@"sections"]
                             objectAtIndex:[indexPath section]]
                            objectForKey:@"rows"];
    return [rows objectAtIndex:[indexPath row]];
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
                    withImages:(BOOL) withImages
{
    static NSString *CellIdentifier = @"Cell";
    
    RadTableViewCell *cell = (RadTableViewCell *)
    [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[RadTableViewCell alloc]
                initWithStyle:UITableViewCellStyleDefault
                reuseIdentifier:CellIdentifier];
    }
    [cell resetWithIndexPath:indexPath controller:self];
    
    NSDictionary *row = [self rowForIndexPath:indexPath];
    cell.contents = row;
    
    if ([row objectForKey:@"action"]) {
        cell.selectionStyle = UITableViewCellSelectionStyleGray;
    } else {
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    
    if ([row objectForKey:@"accessory"] && [[row objectForKey:@"accessory"] isEqualToString:@"disclosure"]) {
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    } else if ([row objectForKey:@"accessory"] && [[row objectForKey:@"accessory"] isEqualToString:@"checkmark"]) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    
    NSAttributedString *attributedText = [row objectForKey:@"attributedText"];
    if (attributedText) {
        cell.textLabel.attributedText = attributedText;
    } else {
        NSString *markdown = [row objectForKey:@"markdown"];
        CGFloat width = self.tableView.bounds.size.width;
        if (markdown) {
            NSString *attributes = [row objectForKey:@"attributes"];
            cell.textLabel.attributedText = [[RadStyleManager sharedInstance]
                                             attributedStringForMarkdown:markdown
                                             withAttributesNamed:attributes];
        } else {
            cell.textLabel.text = [row objectForKey:@"text"];
        }
    }
    
    id input = [row objectForKey:@"input"];
    if (input) {
        id type = [[input objectForKey:@"type"] lowercaseString];
        if ([type isEqualToString:@"rating"]) {
            if (!cell.slider) {
                cell.slider = [[RadSlider alloc] initWithFrame:CGRectZero];
                cell.slider.minimumValue = -10;
                cell.slider.maximumValue = 10;
                cell.slider.value = 0;
                cell.slider.minimumValueImage = [UIImage imageNamed:@"no.png"];
                cell.slider.maximumValueImage = [UIImage imageNamed:@"yes.png"];
                [cell.slider addTarget:self action:@selector(sliderValueDidChange:) forControlEvents:UIControlEventValueChanged];
                [cell addSubview:cell.slider];
                if (withImages) {
                    cell.slider.formId = [self.contents objectForKey:@"form"];
                    cell.slider.itemId = [input objectForKey:@"id"];
                    cell.slider.value = [[[RadFormDataManager sharedInstance]
                                          valueForFormId:cell.slider.formId
                                          itemId:cell.slider.itemId]
                                         floatValue];
                }
            }
        } else if ([type isEqualToString:@"text"]) {
            if (!cell.textView) {
                cell.textView = [[RadTextView alloc] initWithFrame:CGRectZero];
                cell.textView.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1.0];
                cell.textView.delegate = self;
                [cell addSubview:cell.textView];
                
                if (withImages) {
                    cell.textView.formId = [self.contents objectForKey:@"form"];
                    cell.textView.itemId = [input objectForKey:@"id"];
                    cell.textView.text = [[RadFormDataManager sharedInstance]
                                          valueForFormId:cell.textView.formId
                                          itemId:cell.textView.itemId];
                }
            }
        } else if ([type isEqualToString:@"field"]) {
            if (!cell.textField) {
                cell.textField = [[RadTextField alloc] initWithFrame:CGRectZero];
                cell.textField.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1.0];
                cell.textField.delegate = self;
                cell.textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
                cell.textField.autocorrectionType = UITextAutocorrectionTypeNo;
                [cell addSubview:cell.textField];
                
                if (withImages) {
                    cell.textField.formId = [self.contents objectForKey:@"form"];
                    cell.textField.itemId = [input objectForKey:@"id"];
                    cell.textField.text = [[RadFormDataManager sharedInstance]
                                           valueForFormId:cell.textField.formId
                                           itemId:cell.textField.itemId];
                }
            }
        }
    }
    
    if (withImages) {
        
        NSDictionary *imageInfo = [row objectForKey:@"image"];
        if (imageInfo && [imageInfo isKindOfClass:[NSDictionary class]]) {
            
            NSString *imageName = [imageInfo objectForKey:@"filename"];
            
            // if you want to add an image to your cell, here's how
            static dispatch_queue_t backgroundQueue = 0;
            if (!backgroundQueue) {
                backgroundQueue = dispatch_queue_create("render", NULL);
            }
            
            CGFloat s = 60 * [RadStyleManager sharedInstance].deviceImageScale;
            s *= [[UIScreen mainScreen] scale];
            
            id position = [imageInfo objectForKey:@"position"];
            if ([position isKindOfClass:[NSString class]] &&
                [position isEqualToString:@"top"]) {
                s = 290*[RadStyleManager sharedInstance].deviceTextScale;
            }
            
            id mask = [imageInfo objectForKey:@"mask"];
            if (!mask) {
                mask = @"none";
            }
            if (YES) {
                int n = ([indexPath section] + [indexPath row]) % 3;
                CGFloat r = (n == 0) ? 0.95 : 0.95;
                CGFloat g = (n == 1) ? 0.95 : 0.95;
                CGFloat b = (n == 2) ? 0.95 : 0.95;
                
                cell.imageView.image = [UIImage rad_solidShape:mask
                                                       ofColor:[UIColor colorWithRed:r green:g blue:b alpha:1]
                                                          size:CGSizeMake(s,s)];
            }
            
            dispatch_async(backgroundQueue, ^(void) {
                [[Conference sharedInstance] fetchImageWithName:imageName
                                                     completion:^(UIImage *image) {
                                                         dispatch_async(dispatch_get_main_queue(), ^(void) {
                                                             if ([cell.indexPath isEqual:indexPath]) {
                                                                 UIImage *imageToDisplay = image;
                                                                 if ([mask isKindOfClass:[NSString class]] &&
                                                                     ![mask isEqualToString:@"none"]) {
                                                                     imageToDisplay = [image rad_maskImageWithShape:mask size:CGSizeMake(s,s)];
                                                                 } else {
                                                                     imageToDisplay = image;
                                                                 }
                                                                 cell.imageView.image = imageToDisplay;
                                                             }
                                                         });
                                                     }];
            });
        }
    }
    return cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [self tableView:tableView cellForRowAtIndexPath:indexPath withImages:YES];
}

- (NSString *) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    NSMutableDictionary *sectionInfo = [[self.contents objectForKey:@"sections"]
                                        objectAtIndex:section];
    NSMutableDictionary *headerInfo = [sectionInfo objectForKey:@"header"];
    NSString *title = [headerInfo objectForKey:@"text"];
    return title;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    id row = [self rowForIndexPath:indexPath];
    id action = [row objectForKey:@"action"];
    if ([action isKindOfClass:[NSString class]]) {
        NSArray *parts = [action componentsSeparatedByString:@" "];
        if ([parts count] > 2) {
            NSString *verb = [parts objectAtIndex:0];
            NSString *controllerName = [parts objectAtIndex:1];
            NSString *arguments = ([parts count] >= 3) ? [parts objectAtIndex:2] : @"";
            if ([verb isEqualToString:@"push"]) {
                Class controllerClass = NSClassFromString(controllerName);
                if ([controllerClass isSubclassOfClass:[RadTableViewController class]]) {
                    RadTableViewController *controller = [[controllerClass alloc] initWithParameterString:arguments];
                    [self.navigationController pushViewController:controller animated:YES];
                    return;
                }
            } else if ([verb isEqualToString:@"modal"]) {
                Class controllerClass = NSClassFromString(controllerName);
                if (controllerClass) {
                    id controller = [[controllerClass alloc] initWithParameterString:arguments];
                    if ([controller isKindOfClass:[RadWebViewController class]]) {
                        [self.navigationController presentViewController:controller
                                                                animated:YES
                                                              completion:^{}];
                    } else {
                        RadNavigationController *modalNavigationController =
                        [[RadNavigationController alloc] initWithRootViewController:controller];
                        [self.navigationController presentViewController:modalNavigationController
                                                                animated:YES
                                                              completion:^{}];
                    }
                }
                return;
            }
        } else if ([parts count] == 2) {
            UIViewController *childController;
            NSString *verb = [parts objectAtIndex:0];
            NSString *path = [parts objectAtIndex:1];
            id page = [[RadRequestRouter sharedRouter] pageForPath:path];
            if (page) {
                RadTableViewController *controller = [[RadTableViewController alloc] init];
                controller.contents = page;
                childController = controller;
            } else {
                RadWebViewController *controller = [[RadWebViewController alloc] initWithParameterString:path];
                childController = controller;
            }
            if ([verb isEqualToString:@"push"]) {
                [self.navigationController pushViewController:childController animated:YES];
            } else if ([verb isEqualToString:@"modal"]) {
                if ([childController isKindOfClass:[RadWebViewController class]]) {
                    [self.navigationController presentViewController:childController
                                                            animated:YES
                                                          completion:^{}];
                } else {
                    RadNavigationController *modalNavigationController =
                    [[RadNavigationController alloc] initWithRootViewController:childController];
                    [self.navigationController presentViewController:modalNavigationController
                                                            animated:YES
                                                          completion:^{}];
                }
            }
        }
    } else if ([action isKindOfClass:[NuBlock class]]) {
        NuBlock *actionBlock = (NuBlock *) action;
        NuCell *args = [[NuCell alloc] init];
        [args setCar:self];
        [actionBlock evalWithArguments:args context:[[Nu sharedParser] context]];
        
    } else if (action) {
        void (^action)() = [row objectForKey:@"action"];
        if (action) {
            action();
        }
    } else if ([row objectForKey:@"map"]) {
        NSDictionary *mapInfo = [row objectForKey:@"map"];
        
        NSString *title = [mapInfo objectForKey:@"title"];
        double latitude = [[mapInfo objectForKey:@"latitude"] floatValue];
        double longitude = [[mapInfo objectForKey:@"longitude"] floatValue];
        
        // Create an MKMapItem to pass to the Maps app
        CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake(latitude, longitude);
        MKPlacemark *placemark = [[MKPlacemark alloc] initWithCoordinate:coordinate
                                                       addressDictionary:nil];
        MKMapItem *mapItem = [[MKMapItem alloc] initWithPlacemark:placemark];
        [mapItem setName:title];
        // Pass the map item to the Maps app
        [mapItem openInMapsWithLaunchOptions:nil];
    }
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    id row = [self rowForIndexPath:indexPath];
    id height = [row objectForKey:@"height"];
    if (height) {
        return [height floatValue] * [[RadStyleManager sharedInstance] fontScale];
    } else {
        // compute the height
        RadTableViewCell *cell = (RadTableViewCell *) [self tableView:tableView
                                                cellForRowAtIndexPath:indexPath
                                                           withImages:NO];
        CGRect cellFrame = cell.frame;
        cellFrame.size.width = self.tableView.bounds.size.width;
        cell.frame = cellFrame;
        cell.contents = row;
        [cell layoutSubviews];
        CGRect textLabelFrame = cell.textLabel.frame;
        textLabelFrame.size.height = 9999999;
        cell.textLabel.frame = textLabelFrame;
        [cell.textLabel sizeToFit];
        
        CGFloat minimumHeight = 60 * [[RadStyleManager sharedInstance] fontScale];
        if ([row objectForKey:@"image"]) {
            minimumHeight = (60 + 10) * [RadStyleManager sharedInstance].deviceImageScale;
        }
        
        return MAX(minimumHeight, ceil(textLabelFrame.origin.y + cell.textLabel.frame.size.height)+10);
    }
}

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)sectionIndex
{
    NSDictionary *section = [[self.contents objectForKey:@"sections"] objectAtIndex:sectionIndex];
    NSDictionary *header = [section objectForKey:@"header"];
    if (header) {
        return 20 * [RadStyleManager sharedInstance].fontScale;
    } else {
        return 0;
    }
}

- (NSArray *) sectionIndexTitlesForTableView:(UITableView *)tableView
{
    return [self.contents objectForKey:@"index"];
}

#pragma mark - slider action handler

- (void) sliderValueDidChange:(UISlider *) slider
{
    RadSlider *smartView = (RadSlider *) slider;
    NSString *formId = smartView.formId;
    NSString *itemId = smartView.itemId;
    [[RadFormDataManager sharedInstance] setValue:@(slider.value)
                                        forFormId:formId
                                           itemId:itemId];
}

#pragma mark - text view delegate

- (void) textViewDidBeginEditing:(UITextView *)textView
{
    if (!self.rightBarButtonItemStack) {
        self.rightBarButtonItemStack = [NSMutableArray array];
    }
    if (self.navigationItem.rightBarButtonItem) {
        [self.rightBarButtonItemStack addObject:self.navigationItem.rightBarButtonItem];
    }
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]
                                              initWithTitle:@"Done"
                                              style:UIBarButtonItemStyleDone
                                              target:self
                                              action:@selector(doneButtonPressed:)];
    self.activeTextView = (RadTextView *) textView;
}

- (void)textViewDidEndEditing:(UITextView *)textView
{
    self.navigationItem.rightBarButtonItem = [self.rightBarButtonItemStack lastObject];
    [self.rightBarButtonItemStack removeLastObject];
    if (textView == self.activeTextView) {
        self.activeTextView = nil;
    }
    RadTextView *smartView = (RadTextView *) textView;
    NSString *formId = smartView.formId;
    NSString *itemId = smartView.itemId;
    [[RadFormDataManager sharedInstance] setValue:smartView.text
                                        forFormId:formId
                                           itemId:itemId];
}

- (void) doneButtonPressed:(id) sender
{
    [self.activeTextView resignFirstResponder];
    [self.activeTextField resignFirstResponder];
}

- (void) textFieldDidBeginEditing:(UITextField *)textField
{
    if (!self.rightBarButtonItemStack) {
        self.rightBarButtonItemStack = [NSMutableArray array];
    }
    [self.rightBarButtonItemStack addObject:self.navigationItem.rightBarButtonItem];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]
                                              initWithTitle:@"Done"
                                              style:UIBarButtonItemStyleDone
                                              target:self
                                              action:@selector(doneButtonPressed:)];
    self.activeTextField = (RadTextField *) textField;
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    self.navigationItem.rightBarButtonItem = [self.rightBarButtonItemStack lastObject];
    [self.rightBarButtonItemStack removeLastObject];
    if (textField == self.activeTextField) {
        self.activeTextField = nil;
    }
    RadTextField *smartField = (RadTextField *) textField;
    NSString *formId = smartField.formId;
    NSString *itemId = smartField.itemId;
    [[RadFormDataManager sharedInstance] setValue:smartField.text
                                        forFormId:formId
                                           itemId:itemId];
}


@end