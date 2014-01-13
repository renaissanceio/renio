//
//  Conference.h
//  #renio
//
//  Created by Tim Burks on 11/4/13.
//  Copyright (c) 2013 Radtastical Inc Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@class RadHTTPResult;

typedef void (^ConnectionCompletionHandler)(NSString *label, RadHTTPResult *result);
typedef void (^ConnectionErrorHandler)(RadHTTPResult *result);
typedef void (^ImageFetchCompletionHandler)(UIImage *image);

@interface Conference : NSObject

// raw API results
@property (nonatomic, strong) NSMutableArray *sessions;
@property (nonatomic, strong) NSMutableArray *speakers;
@property (nonatomic, strong) NSMutableArray *surveys;
@property (nonatomic, strong) NSMutableArray *pages;
@property (nonatomic, strong) NSMutableArray *assets;
@property (nonatomic, strong) NSMutableArray *sponsors;
@property (nonatomic, strong) NSMutableArray *news;
@property (nonatomic, strong) NSMutableArray *properties;

// processed API results
@property (nonatomic, strong) NSMutableDictionary *alphabetizedSpeakers;
@property (nonatomic, strong) NSMutableArray *alphabet;
@property (nonatomic, strong) NSMutableDictionary *sessionsByDay;

+ (instancetype) sharedInstance;

+ (NSString *) cacheDirectory;

- (void) connectWithCompletionHandler:(ConnectionCompletionHandler) completionHandler
                         errorHandler:(ConnectionErrorHandler) errorHandler;

- (void) refreshConferenceWithCompletionHandler:(ConnectionCompletionHandler) handler;

- (void) cancelAllDownloads;

- (NSDictionary *) speakerWithId:(NSString *) speakerId;
- (NSDictionary *) speakerWithName:(NSString *) name;
- (NSDictionary *) sessionWithName:(NSString *) name;
- (NSDictionary *) newsItemWithName:(NSString *) name;
- (NSDictionary *) sponsorWithName:(NSString *) name;
- (NSDictionary *) surveyWithName:(NSString *) name;
- (NSDictionary *) propertyWithName:(NSString *)name;

- (void) fetchImageWithName:(NSString *) name
                 completion:(ImageFetchCompletionHandler) handler;

@end
