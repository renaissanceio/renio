/*!
 @file RadRequestHandler.m
 @discussion Rad web server request handler.
 @copyright Copyright (c) 2010 Radtastical Inc.
 
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

#import "RadRequestHandler.h"
#import "RadRequest.h"
#import "Nu.h"

@implementation RadRequestHandler

- (NSString *) path {
    return path;
}

- (NSMutableArray *) parts {
    return self->parts;
}

+ (RadRequestHandler *) handlerWithPath:(id)path block:(id)block
{
    RadRequestHandler *handler = [[RadRequestHandler alloc] init];
    handler->path = path;
    handler->parts = [[[NSString stringWithFormat:@"%@", path] componentsSeparatedByString:@"/"] mutableCopy];
    handler->block = block;
    return handler;
}

// Handle a request. Used internally.
- (BOOL) handleRequest:(RadRequest *)request
{
    @autoreleasepool {
        // NSLog(@"handling request %@", [request path]);
        id args = [[NuCell alloc] init];
        [args setCar:request];
        id body = nil;
        if ([block isKindOfClass:[NuCell class]]) {
            id parser = [Nu sharedParser];
            NSMutableDictionary *context = [NSMutableDictionary dictionary];
            [context setObject:[NuSymbolTable sharedSymbolTable] forKey:@"symbols"];
            for (id key in [[request bindings] allKeys]) {
                [parser setValue:[[request bindings] objectForKey:key] forKey:key];
                [context setObject:[[request bindings] objectForKey:key]
                            forKey:[[NuSymbolTable sharedSymbolTable] symbolWithString:key]];
            }
            body = [parser eval:block];
        }
        if ([body isEqual:[NSNull null]]) {
            body = nil;
        }
        // NSLog(@"evaluated to %@", [body description]);
        if (body && [body isKindOfClass:[NSMutableDictionary class]] && ![body objectForKey:@"id"]) {
            [body setObject:request.path forKey:@"id"];
        }
        if (body && [body isKindOfClass:[NSMutableDictionary class]] && ![body objectForKey:@"rendered"]) {
            [body setObject:[NSDate date] forKey:@"rendered"];
        }
        request.result = body;
        return (body != nil);
    }
}

@end
