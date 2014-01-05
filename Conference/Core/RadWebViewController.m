//
//  WebViewController.m
//  #renio
//
//  Created by Tim Burks on 11/9/13.
//  Copyright (c) 2013 Radtastical Inc. All rights reserved.
//

#import "RadWebViewController.h"

@interface RadWebViewController ()
@property (nonatomic, strong) UIToolbar *topBar;
@property (nonatomic, strong) UIWebView *webView;
@property (nonatomic, strong) NSString *path;
@end

@implementation RadWebViewController

- (id)init
{
    self = [super init];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (instancetype) initWithParameterString:(NSString *)string
{
    if (self = [self init]) {
        self.path = string;
    }
    return self;
}

- (UIStatusBarStyle) preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

- (void) loadView
{
    [super loadView];
    self.view.backgroundColor = [UIColor colorWithRed:0.3 green:0.2 blue:0.1 alpha:1.0];
    self.topBar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 20, self.view.bounds.size.width, 44)];
    self.topBar.barTintColor = [UIColor colorWithRed:0.3 green:0.2 blue:0.1 alpha:1.0];
    self.topBar.tintColor = [UIColor whiteColor];
    
    NSArray *items = @[
                       [[UIBarButtonItem alloc] initWithTitle:@"Back"
                                                        style:UIBarButtonItemStylePlain
                                                       target:self
                                                       action:@selector(goBack:)],
                       [[UIBarButtonItem alloc]
                        initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                        target:nil
                        action:NULL],
                       [[UIBarButtonItem alloc] initWithTitle:@"Forward"
                                                        style:UIBarButtonItemStylePlain
                                                       target:self
                                                       action:@selector(goForward:)],
                       [[UIBarButtonItem alloc]
                        initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                        target:nil
                        action:NULL],
                       [[UIBarButtonItem alloc] initWithTitle:@"Safari"
                                                        style:UIBarButtonItemStylePlain
                                                       target:self
                                                       action:@selector(openInSafari:)],
                       [[UIBarButtonItem alloc]
                        initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                        target:nil
                        action:NULL],
                       [[UIBarButtonItem alloc] initWithTitle:@"Done"
                                                        style:UIBarButtonItemStyleDone
                                                       target:self
                                                       action:@selector(close:)]
                       ];
    [self.topBar setItems:items];
    
    [self.view addSubview:self.topBar];
    
    CGRect webViewFrame = self.view.bounds;
    webViewFrame.origin.y = 64;
    webViewFrame.size.height -= 64;
    self.webView = [[UIWebView alloc] initWithFrame:webViewFrame];
    [self.view addSubview:self.webView];
    
    [self loadPath:self.path];
}

- (void) goBack:(id) sender
{
    [self.webView goBack];
}

- (void) goForward:(id) sender
{
    [self.webView goForward];
}

- (void) openInSafari:(id) sender
{
    [[UIApplication sharedApplication] openURL:self.webView.request.URL];
}

- (void) close:(id) sender
{
    [self dismissViewControllerAnimated:YES completion:^{
        
        
    }];
}

- (void) loadPath:(NSString *) path
{
    NSURL *URL = [NSURL URLWithString:path];
    NSURLRequest *request = [NSURLRequest requestWithURL:URL];
    [self.webView loadRequest:request];
}
@end
