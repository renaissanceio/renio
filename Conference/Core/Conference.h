//
//  Conference.h
//  #renio
//
//  Created by Tim Burks on 11/3/13.
//  Copyright (c) 2013 Radtastical Inc Inc. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
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
