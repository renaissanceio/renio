//
//  RadStyleManager.h
//  #renio
//
//  Created by Tim Burks on 11/9/13.
//  Copyright (c) 2013 Radtastical Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RadStyleManager : NSObject

@property (nonatomic, strong) NSMutableDictionary *attributeDictionaries;
@property (nonatomic, assign) CGFloat fontScale;
@property (nonatomic, assign) CGFloat deviceTextScale;
@property (nonatomic, assign) CGFloat deviceImageScale;

+ (instancetype) sharedInstance;

- (NSDictionary *) paragraphAttributesWithTabStops;

- (NSAttributedString *) attributedStringForMarkdown:(NSString *)markdown
                                 withAttributesNamed:(NSString *)attributesName;

- (void) start;

@end
