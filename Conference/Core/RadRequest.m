//
//  RadRequest.m
//  RAD
//
//  Created by Tim Burks on 2/15/11.
//  Copyright 2011 Radtastical, Inc. All rights reserved.
//

#import "RadRequest.h"


@implementation RadRequest
@synthesize path, bindings, result;

- (id) initWithPath:(NSString *) p {
    if (self = [super init]) {
        self.path = p;
        self.bindings = [NSMutableDictionary dictionary];
        self.result = nil;
    }
    return self;
}


@end
