//
//  RadHTTPResult.h
//  UGAPIApp
//
//  Created by Tim Burks on 4/3/13.
//
//

#import <Foundation/Foundation.h>

@interface RadHTTPResult : NSObject
@property (nonatomic, strong) NSHTTPURLResponse *response;
@property (nonatomic, strong) NSData *data;
@property (nonatomic, strong) NSError *error;
@property (nonatomic, strong) id object;
@property (nonatomic, readonly) NSString *UTF8String;

- (instancetype) initWithData:(NSData *) data
                     response:(NSHTTPURLResponse *) response
                        error:(NSError *) error;

- (NSInteger) statusCode;

@end