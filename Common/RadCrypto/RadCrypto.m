/*!
 @file RadCrypto_CommonCrypto.m
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
#import "RadCrypto.h"

#import <CommonCrypto/CommonHMAC.h>
#import <CommonCrypto/CommonDigest.h>
#import <CommonCrypto/CommonCryptor.h>
#import <CommonCrypto/CommonKeyDerivation.h>

@implementation NSData (RadCommonCrypto)

- (NSData *) rad_md5Data
{
    unsigned char result[CC_MD5_DIGEST_LENGTH];
    CC_MD5([self bytes], (CC_LONG) [self length], result);
    return [NSData dataWithBytes:result length:CC_MD5_DIGEST_LENGTH];
}

- (NSData *) rad_sha1Data
{
    unsigned char result[CC_SHA1_DIGEST_LENGTH];
    CC_SHA1([self bytes], (CC_LONG) [self length], result);
    return [NSData dataWithBytes:result length:CC_SHA1_DIGEST_LENGTH];
}

- (NSData *) rad_sha224Data
{
    unsigned char result[CC_SHA224_DIGEST_LENGTH];
    CC_SHA224([self bytes], (CC_LONG) [self length], result);
    return [NSData dataWithBytes:result length:CC_SHA224_DIGEST_LENGTH];
}

- (NSData *) rad_sha256Data
{
    unsigned char result[CC_SHA256_DIGEST_LENGTH];
    CC_SHA256([self bytes], (CC_LONG) [self length], result);
    return [NSData dataWithBytes:result length:CC_SHA256_DIGEST_LENGTH];
}

- (NSData *) rad_sha384Data
{
    unsigned char result[CC_SHA384_DIGEST_LENGTH];
    CC_SHA384([self bytes], (CC_LONG) [self length], result);
    return [NSData dataWithBytes:result length:CC_SHA384_DIGEST_LENGTH];
}

- (NSData *) rad_sha512Data
{
    unsigned char result[CC_SHA512_DIGEST_LENGTH];
    CC_SHA512([self bytes], (CC_LONG) [self length], result);
    return [NSData dataWithBytes:result length:CC_SHA512_DIGEST_LENGTH];
}

- (NSData *) rad_hmacMd5DataWithKey:(NSData *) key
{
    unsigned char result[CC_MD5_DIGEST_LENGTH];
    CCHmac(kCCHmacAlgMD5, [key bytes], [key length], [self bytes], [self length], result);
    return [NSData dataWithBytes:result length:CC_MD5_DIGEST_LENGTH];
}

- (NSData *) rad_hmacSha1DataWithKey:(NSData *) key
{
    unsigned char result[CC_SHA1_DIGEST_LENGTH];
    CCHmac(kCCHmacAlgSHA1, [key bytes], [key length], [self bytes], [self length], result);
    return [NSData dataWithBytes:result length:CC_SHA1_DIGEST_LENGTH];
}

- (NSData *) rad_hmacSha224DataWithKey:(NSData *) key
{
    unsigned char result[CC_SHA224_DIGEST_LENGTH];
    CCHmac(kCCHmacAlgSHA224, [key bytes], [key length], [self bytes], [self length], result);
    return [NSData dataWithBytes:result length:CC_SHA224_DIGEST_LENGTH];
}

- (NSData *) rad_hmacSha256DataWithKey:(NSData *) key
{
    unsigned char result[CC_SHA256_DIGEST_LENGTH];
    CCHmac(kCCHmacAlgSHA256, [key bytes], [key length], [self bytes], [self length], result);
    return [NSData dataWithBytes:result length:CC_SHA256_DIGEST_LENGTH];
}

- (NSData *) rad_hmacSha384DataWithKey:(NSData *) key
{
    unsigned char result[CC_SHA384_DIGEST_LENGTH];
    CCHmac(kCCHmacAlgSHA384, [key bytes], [key length], [self bytes], [self length], result);
    return [NSData dataWithBytes:result length:CC_SHA384_DIGEST_LENGTH];
}

- (NSData *) rad_hmacSha512DataWithKey:(NSData *) key
{
    unsigned char result[CC_SHA512_DIGEST_LENGTH];
    CCHmac(kCCHmacAlgSHA512, [key bytes], [key length], [self bytes], [self length], result);
    return [NSData dataWithBytes:result length:CC_SHA512_DIGEST_LENGTH];
}

@end

