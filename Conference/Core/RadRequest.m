//
//  RadRequest.m
//  #renio
//
//  Created by Tim Burks on 2/15/11.
//  Copyright 2011 Radtastical, Inc. All rights reserved.
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
