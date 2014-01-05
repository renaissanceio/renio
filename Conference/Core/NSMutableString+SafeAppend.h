//
//  NSMutableString+SafeAppend.h
//  #renio
//
//  Created by Tim Burks on 11/10/13.
//  Copyright (c) 2013 Radtastical Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSMutableString (SafeAppend)

- (BOOL) rad_safelyAppendString:(NSString *) string;

@end
