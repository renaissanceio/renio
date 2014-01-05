//
//  RadHTTPHelpers.h
//  RadHTTP
//
//  Created by Tim Burks on 2/24/12.
//  Copyright (c) 2012 Radtastical Inc. All rights reserved.
//
#import <Foundation/Foundation.h>

@interface NSString (RadHTTPHelpers)
- (NSString *) rad_URLEncodedString;
- (NSString *) rad_URLDecodedString;
- (NSDictionary *) rad_URLQueryDictionary;
@end

@interface NSData (RadHTTPHelpers)
- (NSDictionary *) rad_URLQueryDictionary;
- (NSDictionary *) rad_JSONDictionary;
@end

@interface NSDictionary (RadHTTPHelpers)
- (NSString *) rad_URLQueryString;
- (NSData *) rad_URLQueryData;
- (NSString *) rad_JSONString;
- (NSData *) rad_JSONData;
@end


