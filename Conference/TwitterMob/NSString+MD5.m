//
//  NSString+MD5.m
//  CSOP
//
//  Created by Aleksey Novicov on 9/30/12.
//  Copyright (c) 2012 Yodel Code LLC. All rights reserved.
//

#import "NSString+MD5.h"
#import <CommonCrypto/CommonDigest.h>

@implementation NSString (MD5)

- (NSString *)MD5 {
	unsigned int outputLength = CC_MD5_DIGEST_LENGTH;
	unsigned char output[outputLength];
	
	CC_MD5(self.UTF8String, [self UTF8Length], output);
	return [self toHexString:output length:outputLength];;
}

- (unsigned int)UTF8Length {
	return (unsigned int) [self lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
}

- (NSString *)toHexString:(unsigned char *) data length: (unsigned int) length {
	NSMutableString* hash = [NSMutableString stringWithCapacity:length * 2];
	for (unsigned int i = 0; i < length; i++) {
		[hash appendFormat:@"%02x", data[i]];
		data[i] = 0;
	}
	return hash;
}

@end
