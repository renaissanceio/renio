/*!
 @file RadCrypto.h
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

#import <Foundation/Foundation.h>

@interface NSData (RadCrypto)
- (NSData *) rad_md5Data;
- (NSData *) rad_sha1Data;
- (NSData *) rad_sha224Data;
- (NSData *) rad_sha256Data;
- (NSData *) rad_sha384Data;
- (NSData *) rad_sha512Data;
- (NSData *) rad_hmacMd5DataWithKey:(NSData *) key;
- (NSData *) rad_hmacSha1DataWithKey:(NSData *) key;
- (NSData *) rad_hmacSha224DataWithKey:(NSData *) key;
- (NSData *) rad_hmacSha256DataWithKey:(NSData *) key;
- (NSData *) rad_hmacSha384DataWithKey:(NSData *) key;
- (NSData *) rad_hmacSha512DataWithKey:(NSData *) key;
@end
