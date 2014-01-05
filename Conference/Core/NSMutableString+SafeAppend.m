//
//  NSMutableString+SafeAppend.m
//  #renio
//
//  Created by Tim Burks on 11/10/13.
//  Copyright (c) 2013 Radtastical Inc. All rights reserved.
//

#import "NSMutableString+SafeAppend.h"

@implementation NSMutableString (SafeAppend)

- (BOOL) rad_safelyAppendString:(NSString *) string
{
    if ([string isKindOfClass:[NSString class]]) {
        @autoreleasepool {
            [self appendString:string];
        }
        return YES;
    } else {
        return NO;
    }
}
@end
