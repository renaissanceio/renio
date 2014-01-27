//
//  RadHTTPResult.m
//
//  Created by Tim Burks on 4/3/13.
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

#import "RadHTTPResult.h"

@implementation RadHTTPResult

- (instancetype) initWithData:(NSData *) data
                     response:(NSHTTPURLResponse *) response
                        error:(NSError *) error
{
    if (self = [super init]) {
        self.data = data;
        self.response = (NSHTTPURLResponse *) response;
        self.error = error;
    }
    return self;
}

- (NSInteger) statusCode
{
    return [self.response statusCode];
}

- (id) object {
    if (!_object && !_error) {
        NSString *contentType = [[self.response allHeaderFields] objectForKey:@"Content-Type"];
        if ([contentType isEqualToString:@"application/xml"]) {
            // assume the response data is a property list
            _object = [NSPropertyListSerialization propertyListWithData:_data options:0 format:nil error:nil];
            NSLog(@"%@", [_object description]);
        } else {
            // otherwise let's assume we got JSON
            NSError *error;
            // NSLog(@"JSON %@", [[NSString alloc] initWithData:_data encoding:NSUTF8StringEncoding]);
            _object = [NSJSONSerialization JSONObjectWithData:_data options:NSJSONReadingMutableContainers error:&error];
            _error = error;
            if (_error) {
                NSLog(@"JSON ERROR: %@", [error description]);
            }
        }
    }
    return _object;
}

- (NSString *) UTF8String {
    return [[NSString alloc] initWithData:self.data encoding:NSUTF8StringEncoding];
}

@end