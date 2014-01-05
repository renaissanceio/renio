/*!
 @file RadRequestRouter.m
 @discussion Rad request router.
 @copyright Copyright (c) 2010-2014 Radtastical Inc.
 
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

#import "RadRequest.h"
#import "RadRequestHandler.h"
#import "RadRequestRouter.h"

static NSString *spaces(int n)
{
    NSMutableString *result = [NSMutableString string];
    for (int i = 0; i < n; i++) {
        [result appendString:@" "];
    }
    return result;
}

@interface RadRequestRouter (Private)
+ (RadRequestRouter *) routerWithToken:(id) token;
- (NSString *) token;
- (void) insertHandler:(RadRequestHandler *) handler level:(int) level;
- (BOOL) routeAndHandleRequest:(RadRequest *) request parts:(NSArray *) parts level:(int) level;
@end

@implementation RadRequestRouter

+ (RadRequestRouter *) sharedRouter
{
    static RadRequestRouter *router = nil;
    if (!router) {
        router = [RadRequestRouter router];
    }
    return router;
}

+ (RadRequestRouter *) router
{
    return [self routerWithToken:@""];
}

+ (RadRequestRouter *) routerWithToken:(NSString *) token
{
    RadRequestRouter *router = [[self alloc] init];
    router->keyHandlers = [[NSMutableDictionary alloc] init];
    router->patternHandlers = [[NSMutableArray alloc] init];
	router->token = [token copy];
    if ([token isEqualToString:@""]) {
        router.staticPages = [NSMutableDictionary dictionary];
    }
    return router;
}

- (NSString *) token
{
    return token;
}

- (NSString *) descriptionWithLevel:(int) level
{
    NSMutableString *result;
    if (level >= 2) {
        result = [NSMutableString stringWithFormat:@"%@/%@%@\n",
                  spaces(level),
                  self->token,
                  self->handler ? @"  " : @" -"];
    }
    else {
        result = [NSMutableString stringWithFormat:@"%@%@\n",
                  spaces(level),
                  self->token];
    }
    id keys = [[self->keyHandlers allKeys] sortedArrayUsingSelector:@selector(compare:)];
    for (int i = 0; i < [keys count]; i++) {
        id key = [keys objectAtIndex:i];
        id value = [self->keyHandlers objectForKey:key];
        [result appendString:[value descriptionWithLevel:(level+1)]];
    }
    for (int i = 0; i < [self->patternHandlers count]; i++) {
        id value = [self->patternHandlers objectAtIndex:i];
        [result appendString:[value descriptionWithLevel:(level+1)]];
    }
    return result;
}

- (NSString *) description
{
    return [self descriptionWithLevel:0];
}

- (id) pageForPath:(NSString *) path
{
    if (self.staticPages) {
        id page = [self.staticPages objectForKey:path];
        if (page) {
            return page;
        }
    }
    RadRequest *request = [[RadRequest alloc] initWithPath:path];
    if ([self routeAndHandleRequest:request]) {
        return [request result];
    } else {
        return nil;
    }
}

- (BOOL) routeAndHandleRequest:(RadRequest *) request parts:(NSArray *) parts level:(int) level
{
    if (level == [parts count]) {
        BOOL handled = NO;
        @try
        {
            // NSLog(@"handling request %@", request.path);
            handled = [self->handler handleRequest:request];
        }
        @catch (id exception) {
            NSLog(@"Rad handler exception: %@ %@", [exception description], [request description]);
            if (YES) {                            // DEBUGGING
                // [request setContentType:@"text/plain"];
                // [request respondWithString:[exception description]];
                handled = YES;
            }
        }
        return handled;
    }
    else {
        id key = [parts objectAtIndex:level];
        id child = [self->keyHandlers objectForKey:key];
        if (child) {
            if ([child routeAndHandleRequest:request parts:parts level:(level+1)]) {
                return YES;
            }
        }
        for (int i = 0; i < [self->patternHandlers count]; i++) {
            child = [self->patternHandlers objectAtIndex:i];
			NSString *childToken = [child token];
            if ([childToken characterAtIndex:0] == '*') {
                NSArray *remainingParts = [parts subarrayWithRange:NSMakeRange(level, [parts count] - level)];
                NSString *remainder = [remainingParts componentsJoinedByString:@"/"];
                [[request bindings] setObject:remainder
                                       forKey:[childToken substringToIndex:([childToken length]-1)]];
                if ([child routeAndHandleRequest:request parts:parts level:(int)[parts count]]) {
                    return YES;
                }
            }
            else {
                [[request bindings] setObject:key
                                       forKey:[childToken substringToIndex:([childToken length]-1)]];
                if ([child routeAndHandleRequest:request parts:parts level:(level + 1)]) {
                    return YES;
                }
            }
            // otherwise, remove bindings and continue
            [[request bindings] removeObjectForKey:[childToken substringToIndex:([childToken length]-1)]];
        }
        return NO;
    }
}

- (BOOL) routeAndHandleRequest:(RadRequest *) request {
    id parts = [[request path] componentsSeparatedByString:@"/"];
    if (([parts count] > 2) && [[parts lastObject] isEqualToString:@""]) {
        parts = [parts subarrayWithRange:NSMakeRange(0, [parts count]-1)];
    }
    return [self routeAndHandleRequest:request parts:parts level:0];
}

- (void) insertHandler:(RadRequestHandler *) h level:(int) level
{
    if (level == [[h parts] count]) {
        self->handler = h;
    }
    else {
        id key = [[h parts] objectAtIndex:level];
        BOOL key_is_pattern = ([key length] > 0) && ([key characterAtIndex:([key length] - 1)] == ':');
        id child = key_is_pattern ? nil : [self->keyHandlers objectForKey:key];
        if (!child) {
            child = [RadRequestRouter routerWithToken:key];
        }
        if (key_is_pattern) {
            [self->patternHandlers addObject:child];
        }
        else {
            [self->keyHandlers setObject:child forKey:key];
        }
        [child insertHandler:h level:level+1];
    }
}

// call this on the root router
- (void) addHandler:(id) h
{
    [self insertHandler:h level:0];
}

- (void) reset {
    keyHandlers = [[NSMutableDictionary alloc] init];
    patternHandlers = [[NSMutableArray alloc] init];
}

@end
