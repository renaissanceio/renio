//
//  RadHTTPHelpers.m
//
//  Created by Tim Burks on 2/24/12.
//  Copyright (c) 2012 Radtastical Inc. All rights reserved.
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

#import "RadHTTPHelpers.h"
#import <wctype.h>

static unichar char_to_int(unichar c)
{
    switch (c) {
        case '0': return 0;
        case '1': return 1;
        case '2': return 2;
        case '3': return 3;
        case '4': return 4;
        case '5': return 5;
        case '6': return 6;
        case '7': return 7;
        case '8': return 8;
        case '9': return 9;
        case 'A': case 'a': return 10;
        case 'B': case 'b': return 11;
        case 'C': case 'c': return 12;
        case 'D': case 'd': return 13;
        case 'E': case 'e': return 14;
        case 'F': case 'f': return 15;
    }
    return 0;                                     // not good
}

static char int_to_char[] = "0123456789ABCDEF";

@implementation NSString (RadHTTPHelpers)

- (NSString *) rad_URLEncodedString
{
    NSMutableString *result = [NSMutableString string];
    int i = 0;
    const char *source = [self cStringUsingEncoding:NSUTF8StringEncoding];
    unsigned long max = strlen(source);
    while (i < max) {
        unsigned char c = source[i++];
        if (c == ' ') {
            [result appendString:@"%20"];
        }
        else if (iswalpha(c) || iswdigit(c) || (c == '-') || (c == '.') || (c == '_') || (c == '~')) {
            [result appendFormat:@"%c", c];
        }
        else {
            [result appendString:[NSString stringWithFormat:@"%%%c%c", int_to_char[(c/16)%16], int_to_char[c%16]]];
        }
    }
    return result;
}

- (NSString *) rad_URLDecodedString
{
    int i = 0;
    NSUInteger max = [self length];
    char *buffer = (char *) malloc ((max + 1) * sizeof(char));
    int j = 0;
    while (i < max) {
        char c = [self characterAtIndex:i++];
        switch (c) {
            case '+':
                buffer[j++] = ' ';
                break;
            case '%':
                buffer[j++] =
                char_to_int([self characterAtIndex:i])*16
                + char_to_int([self characterAtIndex:i+1]);
                i = i + 2;
                break;
            default:
                buffer[j++] = c;
                break;
        }
    }
    buffer[j] = 0;
    NSString *result = [NSMutableString stringWithCString:buffer encoding:NSUTF8StringEncoding];
    if (!result) result = [NSMutableString stringWithCString:buffer encoding:NSASCIIStringEncoding];
    free(buffer);
    return result;
}

- (NSDictionary *) rad_URLQueryDictionary
{
    NSMutableDictionary *result = [NSMutableDictionary dictionary];
    NSArray *pairs = [self componentsSeparatedByString:@"&"];
    int i;
    NSUInteger max = [pairs count];
    for (i = 0; i < max; i++) {
        NSArray *pair = [[pairs objectAtIndex:i] componentsSeparatedByString:@"="];
        if ([pair count] == 2) {
            NSString *key = [[pair objectAtIndex:0] rad_URLDecodedString];
            NSString *value = [[pair objectAtIndex:1] rad_URLDecodedString];
            [result setObject:value forKey:key];
        }
    }
    return result;
}

@end

@implementation NSDictionary (RadHTTPHelpers)

- (NSString *) rad_URLQueryString
{
    NSMutableString *result = [NSMutableString string];
    NSEnumerator *keyEnumerator = [[[self allKeys] sortedArrayUsingSelector:@selector(compare:)] objectEnumerator];
    id key;
    while ((key = [keyEnumerator nextObject])) {
        id value = [self objectForKey:key];
        if (![value isKindOfClass:[NSString class]]) {
            if ([value respondsToSelector:@selector(stringValue)]) {
                value = [value stringValue];
            }
        }
        if ([value isKindOfClass:[NSString class]]) {
            if ([result length] > 0) [result appendString:@"&"];
            [result appendString:[NSString stringWithFormat:@"%@=%@",
                                  [key rad_URLEncodedString],
                                  [value rad_URLEncodedString]]];
        }
    }
    return [NSString stringWithString:result];
}

- (NSData *) rad_URLQueryData
{
    return [[self rad_URLQueryString] dataUsingEncoding:NSUTF8StringEncoding];
}

- (NSString *) rad_JSONString
{
    return [[NSString alloc] initWithData:[self rad_JSONData] encoding:NSUTF8StringEncoding];
}

- (NSData *) rad_JSONData
{
    return [NSJSONSerialization dataWithJSONObject:self options:0 error:NULL];
}

@end

@implementation NSData (RadHTTPHelpers)

- (NSDictionary *) rad_URLQueryDictionary {
    return [[[NSString alloc] initWithData:self encoding:NSUTF8StringEncoding] rad_URLQueryDictionary];
}

- (NSDictionary *) rad_JSONDictionary
{
    return [NSJSONSerialization JSONObjectWithData:self
                                           options:NSJSONReadingMutableContainers
                                             error:NULL];
}

@end

