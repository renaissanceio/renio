//
//  RadRequest.h
//  RAD
//
//  Created by Tim Burks on 2/15/11.
//  Copyright 2011 Radtastical, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface RadRequest : NSObject {

}
@property (nonatomic) NSString *path;
@property (nonatomic) NSMutableDictionary *bindings;
@property (nonatomic) id result;

- (id) initWithPath:(NSString *) p;

@end
