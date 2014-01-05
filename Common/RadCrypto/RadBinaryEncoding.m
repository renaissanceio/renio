/*!
 @file RadBinaryEncoding.m
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

#import "RadBinaryEncoding.h"

@implementation NSData (RadBinaryEncoding)

static const char *const hexEncodingTable = "0123456789abcdef";

- (NSString *) rad_hexEncodedString
{
    NSString *result = nil;
    size_t length = [self length];
    if (0 != length) {
        NSMutableData *temp = [NSMutableData dataWithLength:(length << 1)];
        if (temp) {
            const unsigned char *src = [self bytes];
            unsigned char *dst = [temp mutableBytes];
            if (src && dst) {
                while (length-- > 0) {
                    *dst++ = hexEncodingTable[(*src >> 4) & 0x0f];
                    *dst++ = hexEncodingTable[(*src++ & 0x0f)];
                }
                result = [[NSString alloc] initWithData:temp encoding:NSUTF8StringEncoding];
            }
        }
    }
    return result;
}

#define HEXVALUE(c) (((c >= '0') && (c <= '9')) ? (c - '0') : ((c >= 'a') && (c <= 'f')) ? (c - 'a' + 10) : 0)

+ (id) rad_dataWithHexEncodedString:(NSString *) string
{
    if (string == nil)
        return nil;
    if ([string length] == 0)
        return [NSData data];

    const char *characters = [[string lowercaseString] cStringUsingEncoding:NSASCIIStringEncoding];
    if (characters == NULL)                       //  Not an ASCII string!
        return nil;

    NSInteger length = [string length] / 2;
    char *bytes = (char *) malloc(length * sizeof (char));
    const char *cursor = characters;
    for (int i = 0; i < length; i++) {
        char ch = *(cursor++);
        char cl = *(cursor++);
        bytes[i] = HEXVALUE(ch)*16 + HEXVALUE(cl);
    }
    return [NSData dataWithBytesNoCopy:bytes length:length];
}

static const char base64EncodingTable[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

- (NSString *) rad_base64EncodedString;
{
    if ([self length] == 0)
        return @"";

    char *characters = malloc((([self length] + 2) / 3) * 4);
    if (characters == NULL)
        return nil;
    NSUInteger length = 0;

    NSUInteger i = 0;
    while (i < [self length]) {
        char buffer[3] = {0,0,0};
        short bufferLength = 0;
        while (bufferLength < 3 && i < [self length])
            buffer[bufferLength++] = ((char *)[self bytes])[i++];

        //  Encode the bytes in the buffer to four characters,
        // including padding "=" characters if necessary.
        characters[length++] = base64EncodingTable[(buffer[0] & 0xFC) >> 2];
        characters[length++] = base64EncodingTable[((buffer[0] & 0x03) << 4) | ((buffer[1] & 0xF0) >> 4)];
        if (bufferLength > 1)
            characters[length++] = base64EncodingTable[((buffer[1] & 0x0F) << 2) | ((buffer[2] & 0xC0) >> 6)];
        else characters[length++] = '=';
        if (bufferLength > 2)
            characters[length++] = base64EncodingTable[buffer[2] & 0x3F];
        else characters[length++] = '=';
    }

    return [[NSString alloc]
        initWithBytesNoCopy:characters
        length:length
        encoding:NSASCIIStringEncoding
        freeWhenDone:YES];
}

+ (id) rad_dataWithBase64EncodedString:(NSString *) string
{
    if (string == nil)
        return nil;
    if ([string length] == 0)
        return [NSData data];

    static char *decodingTable = NULL;
    if (decodingTable == NULL) {
        decodingTable = malloc(256);
        if (decodingTable == NULL)
            return nil;
        memset(decodingTable, CHAR_MAX, 256);
        NSUInteger i;
        for (i = 0; i < 64; i++)
            decodingTable[(short)base64EncodingTable[i]] = i;
    }

    const char *characters = [string cStringUsingEncoding:NSASCIIStringEncoding];
    if (characters == NULL)                       //  Not an ASCII string!
        return nil;
    char *bytes = malloc((([string length] + 3) / 4) * 3);
    if (bytes == NULL)
        return nil;
    NSUInteger length = 0;

    NSUInteger i = 0;
    while (YES) {
        char buffer[4];
        short bufferLength;
        for (bufferLength = 0; bufferLength < 4; i++) {
            if (characters[i] == '\0')
                break;
            if (isspace(characters[i]) || characters[i] == '=')
                continue;
            buffer[bufferLength] = decodingTable[(short)characters[i]];
                                                  //  Illegal character!
            if (buffer[bufferLength++] == CHAR_MAX) {
                free(bytes);
                return nil;
            }
        }

        if (bufferLength == 0)
            break;
        if (bufferLength == 1) {                  //  At least two characters are needed to produce one byte!
            free(bytes);
            return nil;
        }

        //  Decode the characters in the buffer to bytes.
        bytes[length++] = (buffer[0] << 2) | (buffer[1] >> 4);
        if (bufferLength > 2)
            bytes[length++] = (buffer[1] << 4) | (buffer[2] >> 2);
        if (bufferLength > 3)
            bytes[length++] = (buffer[2] << 6) | buffer[3];
    }

    realloc(bytes, length);
    return [NSData dataWithBytesNoCopy:bytes length:length];
}

@end
