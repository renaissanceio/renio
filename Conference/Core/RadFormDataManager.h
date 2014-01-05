//
//  RadFormDataManager.h
//  #renio
//
//  Created by Tim Burks on 11/15/13.
//  Copyright (c) 2013 Radtastical Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RadFormDataManager : NSObject
@property (nonatomic, strong) NSMutableDictionary *forms;

+ (instancetype) sharedInstance;

- (void) save;

- (id) valueForFormId:(NSString *) formId itemId:(NSString *) itemId;

- (void) setValue:(id) value forFormId:(NSString *) formId itemId:(NSString *) itemId;

- (NSDictionary *) valuesForFormId:(NSString *) formId;

- (void) clearFormWithId:(NSString *) formId;

@end
