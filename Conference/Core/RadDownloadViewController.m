//
//  DownloadViewController.m
//  #renio
//
//  Created by Tim Burks on 11/13/13.
//  Copyright (c) 2013 Radtastical Inc. All rights reserved.
//

#import "RadDownloadViewController.h"
#import "RadTitleView.h"
#import "Conference.h"
#import "RadStyleManager.h"

@interface RadDownloadViewController ()
@property (nonatomic, strong) NSArray *topics;
@property (nonatomic, strong) NSMutableArray *cells;
@end

@implementation RadDownloadViewController

- (id)init
{
    self = [super init];
    if (self) {
        // Custom initialization
        self.title = @"Updating...";
        self.topics = @[@"Pages",
                        @"Sessions",
                        @"Speakers",
                        @"Sponsors",
                        @"News",
                        @"Surveys",
                        @"Images"];
        self.delegate = (id<RadDownloadViewControllerDelegate>) [[UIApplication sharedApplication] delegate];
    }
    return self;
}

- (void) loadView
{
    [super loadView];
    
    RadTitleView *container = [[RadTitleView alloc]
                                 initWithFrame:CGRectMake(0,0,self.view.bounds.size.width,44)];
    [container setText:self.title];
    self.navigationItem.titleView = container;
    
    UIImage *image = [UIImage imageNamed:@"seedling.png"];
    UIImageView *imageView = [[UIImageView alloc]
                              initWithImage:image];
    CGFloat width = image.size.width/image.size.height*44;
    imageView.frame = CGRectMake(0,0,width,44);
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc]
                                             initWithCustomView:imageView];
    
    self.cells = [NSMutableArray array];
    for (int i = 0; i < [self.topics count]; i++) {
        UITableViewCell *cell = [[UITableViewCell alloc]
                                 initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Cell"];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.textLabel.font = [UIFont fontWithName:@"AvenirNext-Medium"
                                              size:20.0*[[RadStyleManager sharedInstance] fontScale]];
        [self.cells addObject:cell];
    }
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]
                                              initWithTitle:@"Cancel"
                                              style:UIBarButtonItemStylePlain
                                              target:self
                                              action:@selector(cancel:)];
    
    self.tableView.rowHeight = 44 * [[RadStyleManager sharedInstance] fontScale];
}

- (void) cancel:(id) sender
{
    [[Conference sharedInstance] cancelAllDownloads];
    [self.delegate downloadDidFinishSuccessfully:NO];
    [self dismissViewControllerAnimated:YES completion:^{}];
}

- (void) viewDidAppear:(BOOL)animated
{
    [[Conference sharedInstance] refreshConferenceWithCompletionHandler:^(NSString *message) {
        dispatch_async(dispatch_get_main_queue(),
                       ^{
                           for (int i = 0; i < [self.topics count]; i++) {
                               if ([message isEqualToString:[self.topics objectAtIndex:i]]) {
                                   UITableViewCell *cell = [self.cells objectAtIndex:i];
                                   cell.accessoryType = UITableViewCellAccessoryCheckmark;
                                   [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:i inSection:0]]
                                                         withRowAnimation:UITableViewRowAnimationNone];
                               }
                           }
                           // check all cells... we are finished when all are checked.
                           int checkedCellCount = 0;
                           for (UITableViewCell *cell in self.cells) {
                               if (cell.accessoryType == UITableViewCellAccessoryCheckmark) {
                                   checkedCellCount++;
                               }
                           }
                           if (checkedCellCount == [self.cells count]) {
                               double delayInSeconds = 0.2;
                               dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
                               dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                                   [self.delegate downloadDidFinishSuccessfully:YES];
                                   [self dismissViewControllerAnimated:YES completion:^{}];
                               });
                           }
                       });}
     ];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return [self.topics count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [self.cells objectAtIndex:[indexPath row]];
    cell.textLabel.text = [self.topics objectAtIndex:[indexPath row]];
    return cell;
}

@end
