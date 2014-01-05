//
//  RadStyleManager.m
//  #renio
//
//  Created by Tim Burks on 11/9/13.
//  Copyright (c) 2013 Radtastical Inc. All rights reserved.
//

#import "RadStyleManager.h"
#import "markdown_lib.h"
#import "markdown_peg.h"
#import "NSMutableString+SafeAppend.h"

@interface RadStyleManager ()
@property (nonatomic, strong) NSDictionary *fontSizes;
@end

@implementation RadStyleManager

+ (instancetype) sharedInstance
{
    static id instance = nil;
    if (!instance) {
        instance = [[self alloc] init];
    }
    return instance;
}

- (instancetype) init
{
    if (self = [super init]) {
        self.attributeDictionaries = [NSMutableDictionary dictionary];
        [self prepareAttributeDictionaries];
        
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
            self.deviceTextScale = 1.0;
            self.deviceImageScale = 1.0;
        } else {
            self.deviceTextScale = 1.5;
            self.deviceImageScale = 2.0;
        }
    }
    return self;
}

- (NSMutableDictionary *) attributesWithAlignment:(NSTextAlignment) alignment
                                        textScale:(CGFloat) textScale
                                 paragraphSpacing:(CGFloat) paragraphSpacing
{
    NSMutableDictionary *attributes = [[NSMutableDictionary alloc] init];
    // p
    UIFont *paragraphFont = [UIFont fontWithName:@"AvenirNext-Medium" size:14.0*self.fontScale*textScale];
    NSMutableParagraphStyle* pParagraphStyle = [[NSMutableParagraphStyle alloc] init];
    pParagraphStyle.alignment = alignment;
    pParagraphStyle.paragraphSpacing = paragraphSpacing;
    pParagraphStyle.paragraphSpacingBefore = paragraphSpacing;
    //    pParagraphStyle.lineSpacing = 0;
    //    pParagraphStyle.lineHeightMultiple = 0;
    pParagraphStyle.lineBreakMode = NSLineBreakByWordWrapping;
    
    NSDictionary *pAttributes = @{NSFontAttributeName : paragraphFont,
                                  NSParagraphStyleAttributeName : pParagraphStyle};
    
    [attributes setObject:pAttributes forKey:@(PARA)];
    
    // h1
    UIFont *h1Font = [UIFont fontWithName:@"AvenirNext-Bold" size:24.0*self.fontScale*textScale];
    [attributes setObject:@{NSFontAttributeName : h1Font,
                            NSParagraphStyleAttributeName: pParagraphStyle}
                   forKey:@(H1)];
    
    // h2
    UIFont *h2Font = [UIFont fontWithName:@"AvenirNext-Bold" size:18.0*self.fontScale*textScale];
    [attributes setObject:@{NSFontAttributeName : h2Font,
                            NSParagraphStyleAttributeName: pParagraphStyle}
                   forKey:@(H2)];
    
    // h3
    UIFont *h3Font = [UIFont fontWithName:@"AvenirNext-DemiBold" size:17.0*self.fontScale*textScale];
    [attributes setObject:@{NSFontAttributeName : h3Font}
                   forKey:@(H3)];
    
    // em
    UIFont *emFont = [UIFont fontWithName:@"AvenirNext-MediumItalic" size:15.0*self.fontScale*textScale];
    [attributes setObject:@{NSFontAttributeName : emFont}
                   forKey:@(EMPH)];
    
    // strong
    UIFont *strongFont = [UIFont fontWithName:@"AvenirNext-Bold" size:15.0*self.fontScale*textScale];
    [attributes setObject:@{NSFontAttributeName : strongFont}
                   forKey:@(STRONG)];
    
    // ul
    NSMutableParagraphStyle* listParagraphStyle = [[NSMutableParagraphStyle alloc] init];
    listParagraphStyle.headIndent = 16.0*self.fontScale*textScale;
    [attributes setObject:@{NSFontAttributeName : paragraphFont,
                            NSParagraphStyleAttributeName : listParagraphStyle}
                   forKey:@(BULLETLIST)];
    
    // li
    NSMutableParagraphStyle* listItemParagraphStyle = [[NSMutableParagraphStyle alloc] init];
    listItemParagraphStyle.headIndent = 16.0*self.fontScale*textScale;
    [attributes setObject:@{NSFontAttributeName : paragraphFont,
                            NSParagraphStyleAttributeName : listItemParagraphStyle}
                   forKey:@(LISTITEM)];
    
    // a
    UIColor *linkColor = [UIColor blueColor];
    [attributes setObject:@{NSForegroundColorAttributeName : linkColor}
                   forKey:@(LINK)];
    
    // blockquote
    NSMutableParagraphStyle* blockquoteParagraphStyle = [[NSMutableParagraphStyle alloc] init];
    blockquoteParagraphStyle.headIndent = 16.0*textScale;
    blockquoteParagraphStyle.tailIndent = 16.0*textScale;
    blockquoteParagraphStyle.firstLineHeadIndent = 16.0*textScale;
    [attributes setObject:@{NSFontAttributeName : [emFont fontWithSize:18.0*self.fontScale*textScale], NSParagraphStyleAttributeName : pParagraphStyle}
                   forKey:@(BLOCKQUOTE)];
    
    // verbatim (code)
    NSMutableParagraphStyle* verbatimParagraphStyle = [[NSMutableParagraphStyle alloc] init];
    verbatimParagraphStyle.headIndent = 12.0*textScale;
    verbatimParagraphStyle.firstLineHeadIndent = 12.0*textScale;
    UIFont *verbatimFont = [UIFont fontWithName:@"CourierNewPSMT" size:14.0*self.fontScale*textScale];
    [attributes setObject:@{NSFontAttributeName : verbatimFont, NSParagraphStyleAttributeName : verbatimParagraphStyle}
                   forKey:@(VERBATIM)];
    
    return attributes;
}

- (void) prepareAttributeDictionaries
{
    // default markdown attributes
    [self.attributeDictionaries setObject:[self attributesWithAlignment:NSTextAlignmentLeft
                                                              textScale:1.0
                                                       paragraphSpacing:0]
                                   forKey:@"default"];
    
    // right-justified attributes
    [self.attributeDictionaries setObject:[self attributesWithAlignment:NSTextAlignmentRight
                                                              textScale:1.0
                                                       paragraphSpacing:0]
                                   forKey:@"right"];
    
    // centered-text attributes
    [self.attributeDictionaries setObject:[self attributesWithAlignment:NSTextAlignmentCenter
                                                              textScale:1.0
                                                       paragraphSpacing:0]
                                   forKey:@"centered"];
    
    // small text attributes
    [self.attributeDictionaries setObject:[self attributesWithAlignment:NSTextAlignmentLeft
                                                              textScale:0.7
                                                       paragraphSpacing:0]
                                   forKey:@"small"];
    
    // extra-spaced attributes
    [self.attributeDictionaries setObject:[self attributesWithAlignment:NSTextAlignmentLeft
                                                              textScale:1
                                                       paragraphSpacing:10]
                                   forKey:@"spaced"];
}

- (void) updateFontScale
{
    if (!self.fontSizes) {
        self.fontSizes = @{UIContentSizeCategoryExtraSmall:@(0.7),
                           UIContentSizeCategorySmall:@(0.8),
                           UIContentSizeCategoryMedium:@(0.9),
                           UIContentSizeCategoryLarge:@(1.0),
                           UIContentSizeCategoryExtraLarge:@(1.1),
                           UIContentSizeCategoryExtraExtraLarge:@(1.2),
                           UIContentSizeCategoryExtraExtraExtraLarge:@(1.3)};
    }
    
    NSString *preferredSize = [[UIApplication sharedApplication] preferredContentSizeCategory];
    // NSLog(@"preferred text size: %@", preferredSize);
    
    NSNumber *fontScaleValue = [self.fontSizes objectForKey:preferredSize];
    if (fontScaleValue) {
        self.fontScale = [fontScaleValue floatValue] * self.deviceTextScale;
    } else {
        self.fontScale = 1.0 * self.deviceTextScale;
    }
    
    [[UINavigationBar appearance] setBarTintColor:[UIColor colorWithRed:0.3 green:0.2 blue:0.1 alpha:1.0]];
    
    [[UINavigationBar appearance] setTitleTextAttributes:
     @{NSFontAttributeName:[UIFont fontWithName:@"AvenirNext-Bold"
                                           size:15.0*self.fontScale]}];
    
    [[UIBarButtonItem appearance] setTintColor:[UIColor colorWithRed:1 green:1.0 blue:1.0 alpha:1.0]];
    
    [[UIBarButtonItem appearance] setTitleTextAttributes:
     @{NSFontAttributeName:[UIFont fontWithName:@"AvenirNext-Bold"
                                           size:16.0*self.fontScale]}
                                                forState:UIControlStateNormal];
    
    // don't scale these
    [[UITabBarItem appearance] setTitleTextAttributes:
     @{NSFontAttributeName:[UIFont fontWithName:@"AvenirNext-DemiBold"
                                           size:12.0]}
                                             forState:UIControlStateNormal];
    
    [[UILabel appearanceWhenContainedIn:[UITableViewHeaderFooterView class], nil]
     setFont:[UIFont fontWithName:@"AvenirNext-DemiBold"
                             size:16.0]];
    
    [self prepareAttributeDictionaries];
    
    // NSLog(@"font scale is now %f", self.fontScale);
    [[NSNotificationCenter defaultCenter] postNotificationName:@"FontSizeChanged" object:nil];
    
}

- (void) start
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(preferredTextSizeChanged)
                                                 name:UIContentSizeCategoryDidChangeNotification
                                               object:nil];
    [self updateFontScale];
}

- (void) preferredTextSizeChanged
{
    [self updateFontScale];
}

- (NSAttributedString *) attributedStringForMarkdown:(NSString *)markdown
                                 withAttributesNamed:(NSString *)attributesName
{
    NSDictionary *attributes = [self.attributeDictionaries objectForKey:attributesName];
    if (!attributes) {
        attributes = [self.attributeDictionaries objectForKey:@"default"];
    }
    NSAttributedString *result = markdown_to_attr_string(markdown, 0, attributes);
    return result;
}

@end
