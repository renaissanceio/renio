//
//  RadFormDataManager.m
//  #renio
//
//  Created by Tim Burks on 11/15/13.
//  Copyright (c) 2013 Radtastical Inc. All rights reserved.
//

#import "RadFormDataManager.h"

@interface RadFormDataManager ()
@end

@implementation RadFormDataManager

+ (instancetype) sharedInstance
{
    static id instance = nil;
    if (!instance) {
        instance = [[self alloc] init];
    }
    return instance;
}

- (instancetype) init {
    if (self = [super init]) {
        NSData *formData = [NSData dataWithContentsOfFile:[self formsFileName]];
        if (formData) {
            self.forms = [NSPropertyListSerialization propertyListWithData:formData
                                                                   options:NSPropertyListMutableContainersAndLeaves
                                                                    format:NULL
                                                                     error:NULL];
        } else {
            self.forms = [NSMutableDictionary dictionary];
        }
    }
    return self;
}

+ (NSString *) cacheDirectory {
    static NSString *_cacheDirectory = nil;
    if (!_cacheDirectory) {
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
        _cacheDirectory = [paths objectAtIndex:0];
    }
    return _cacheDirectory;
}

- (NSString *) formsFileName
{
    return [[RadFormDataManager cacheDirectory] stringByAppendingPathComponent:@"forms.plist"];
}

- (void) save
{
    NSData *formData = [NSPropertyListSerialization dataFromPropertyList:self.forms
                                                                  format:NSPropertyListBinaryFormat_v1_0
                                                        errorDescription:NULL];
    [formData writeToFile:[self formsFileName] atomically:YES];
}

- (id) valueForFormId:(NSString *) formId itemId:(NSString *) itemId
{
    NSMutableDictionary *form = [self.forms objectForKey:formId];
    if (form) {
        return [form objectForKey:itemId];
    } else {
        return nil;
    }
}

- (void) setValue:(id) value forFormId:(NSString *) formId itemId:(NSString *) itemId
{
    NSMutableDictionary *form = [self.forms objectForKey:formId];
    if (!form) {
        form = [NSMutableDictionary dictionary];
        [self.forms setObject:form forKey:formId];
    }
    [form setObject:value forKey:itemId];
}

- (NSDictionary *) valuesForFormId:(NSString *) formId
{
    return [self.forms objectForKey:formId];
}

- (void) clearFormWithId:(NSString *) formId
{
    [self.forms removeObjectForKey:formId];
}

@end
