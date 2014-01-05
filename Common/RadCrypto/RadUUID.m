/*!
 @file RadUUID.m
 @copyright Copyright (c) 2013 Radtastical Inc.
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

#import "RadUUID.h"
#include "uuid/uuid.h"

@interface RadUUID ()
{
    uuid_t uu;
}
@end

@implementation RadUUID 

- (RadUUID *) init {
   if (self = [super init]) {
       uuid_generate(uu);
   }
   return self;
}

- (NSString *) stringValue {
   char value[37];
   uuid_unparse(uu, value);
   return [NSString stringWithCString:value encoding:NSUTF8StringEncoding];
}

+ (NSString *) sharedIdentifier
{
    NSString *identifier = [[NSUserDefaults standardUserDefaults] objectForKey:@"sharedIdentifier"];
    if (!identifier) {
        identifier = [[[RadUUID alloc] init] stringValue];
        [[NSUserDefaults standardUserDefaults] setObject:identifier forKey:@"sharedIdentifier"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    return identifier;
}

@end
