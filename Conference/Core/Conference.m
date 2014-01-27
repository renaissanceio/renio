//
//  Conference.m
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

#import "RadHTTP.h"
#import "RadRequestRouter.h"
#import "UGConnection.h"
#import "Conference.h"

@interface Conference ()
@property (nonatomic, strong) NSOperationQueue *downloadQueue;
@property (nonatomic, strong) UGConnection *usergrid;
@end

@implementation Conference

+ (instancetype) sharedInstance
{
    static id instance = nil;
    if (!instance) {
        instance = [[self alloc] init];
    }
    return instance;
}

- (instancetype) init
{
    if (self = [super init]) {
        self.usergrid = [UGConnection sharedInstance];
        
        NSString *usergridServer = [[NSUserDefaults standardUserDefaults] valueForKey:@"usergrid_server"];
        NSString *usergridOrganization = [[NSUserDefaults standardUserDefaults] valueForKey:@"usergrid_organization"];
        NSString *usergridApplication = [[NSUserDefaults standardUserDefaults] valueForKey:@"usergrid_application"];
        NSNumber *usergridHTTPS = [[NSUserDefaults standardUserDefaults] valueForKey:@"usergrid_https"];
        
        if (!usergridServer) usergridServer = @"api.usergrid.com";
        if (!usergridOrganization) usergridOrganization = @"radtastical";
        if (!usergridApplication) usergridApplication = @"renaissance";
        if (!usergridHTTPS) usergridHTTPS = @(YES);
        
        if ([usergridHTTPS boolValue]) {
            self.usergrid.server = [@"https://" stringByAppendingString:usergridServer];
        } else {
            self.usergrid.server = [@"http://" stringByAppendingString:usergridServer];
        }
        self.usergrid.organization = usergridOrganization;
        self.usergrid.application = usergridApplication;
        
        self.downloadQueue = [[NSOperationQueue alloc] init];
        [self.downloadQueue setMaxConcurrentOperationCount:2];
        
        for (NSString *collectionName in @[@"pages",
                                           @"sessions",
                                           @"speakers",
                                           @"news",
                                           @"surveys",
                                           @"sponsors",
                                           @"properties"]) {
            [self loadFileForCollection:collectionName];
        }
    }
    return self;
}

- (void) cancelAllDownloads
{
    [self.downloadQueue cancelAllOperations];
}

+ (NSString *) cacheDirectory {
    static NSString *_cacheDirectory = nil;
    if (!_cacheDirectory) {
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
        _cacheDirectory = [paths objectAtIndex:0];
    }
    return _cacheDirectory;
}

- (NSString *) fileNameForCollection:(NSString *) collectionName
{
    return [[[Conference cacheDirectory] stringByAppendingPathComponent:collectionName] stringByAppendingPathExtension:@".json"];
}

- (void) loadFileForCollection:(NSString *) collectionName
{
    NSData *data = [NSData dataWithContentsOfFile:[self fileNameForCollection:collectionName]];
    if (data) {
        id object = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        [self setValue:[object objectForKey:@"entities" ] forKey:collectionName];
    }
    [self processCollection:collectionName];
}

- (void) processCollection:(NSString *) collectionName
{
    if ([collectionName isEqualToString:@"speakers"]) {
        [self processSpeakers];
    } else if ([collectionName isEqualToString:@"sessions"]) {
        [self processSessions];
    } else if ([collectionName isEqualToString:@"pages"]) {
        [self processPages];
    }
}

- (void) processSessions
{
    // sort sessions by time
    NSArray *sortedArray =
    [self.sessions sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        NSString *time1 = [obj1 objectForKey:@"time"];
        NSString *time2 = [obj2 objectForKey:@"time"];
        return [time1 compare:time2];
    }];
    self.sessions = [sortedArray mutableCopy];
    
    // separate sessions into arrays for each day and year
    self.sessionsByDay = [NSMutableDictionary dictionary];
    for (id session in self.sessions) {
        int day = [[session objectForKey:@"day"] intValue];
        int year = [[session objectForKey:@"year"] intValue];
        NSString *key = [NSString stringWithFormat:@"%d_%d", year, day];
        NSMutableArray *sessions = [self.sessionsByDay objectForKey:key];
        if (!sessions) {
            sessions = [NSMutableArray array];
            [self.sessionsByDay setObject:sessions forKey:key];
        }
        [sessions addObject:session];
    }
}

- (void) processSpeakers
{
    // sort speakers alphabetically
    NSArray *sortedArray =
    [self.speakers sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        NSString *lastName1 = [[obj1 objectForKey:@"name_last"] lowercaseString];
        NSString *lastName2 = [[obj2 objectForKey:@"name_last"] lowercaseString];
        return [lastName1 compare:lastName2];
    }];
    self.speakers = [sortedArray mutableCopy];
    
    // group speakers by first letter of last name
    self.alphabetizedSpeakers = [NSMutableDictionary dictionary];
    self.alphabet = [NSMutableArray array];
    for (int i = 0; i < 26; i++) {
        [self.alphabet addObject:[NSString stringWithFormat:@"%c", ('A'+i)]];
    }
    for (int year = 2013; year <= 2014; year++) {
        NSMutableArray *alphabetizedSpeakers = [NSMutableArray array];
        for (int i = 0; i < 26; i++) {
            [alphabetizedSpeakers addObject:[NSMutableArray array]];
        }
        [self.alphabetizedSpeakers setObject:alphabetizedSpeakers forKey:@(year)];
    }
    for (id obj in self.speakers) {
        NSString *lastName = [[obj objectForKey:@"name_last"] uppercaseString];
        int year = [[obj objectForKey:@"year"] intValue];
        char firstLetter = [lastName characterAtIndex:0];
        int i = firstLetter - 'A';
        [[[self.alphabetizedSpeakers objectForKey:@(year)] objectAtIndex:i] addObject:obj];
    }
}

- (void) processPages
{
    for (NSDictionary *page in self.pages) {
        [[[RadRequestRouter sharedRouter] staticPages] setObject:page forKey:[page objectForKey:@"name"]];
    }
}

- (void) connectWithCompletionHandler:(ConnectionCompletionHandler) handler
                         errorHandler:(ConnectionErrorHandler) errorHandler
{
#ifdef AUTHENTICATE
    [RadHTTPClient connectWithRequest:
     [self.usergrid getAccessTokenForApplicationWithUsername:@"wemakeapps"
                                                    password:@"renaissanceio"]
                    completionHandler:^(RadHTTPResult *result) {
                        if (result.statusCode == 200) {
                            [self.usergrid authenticateWithResult:result];
#endif
                            [RadHTTPClient connectWithRequest:
                             [self.usergrid getEntitiesInCollection:@"properties" limit:100]
                                            completionHandler:^(RadHTTPResult *result) {
                                                if (result.statusCode == 200) {
                                                    [[result data] writeToFile:[self fileNameForCollection:@"properties"]
                                                                    atomically:YES];
                                                    self.properties = [[result object] objectForKey:@"entities"];
                                                    handler(@"Done", result);
                                                } else {
                                                    errorHandler(result);
                                                }
                                            }];
#ifdef AUTHENTICATE
                        } else {
                            errorHandler(result);
                        }
                    }];
#endif
}

- (void) refreshConferenceWithCompletionHandler:(ConnectionCompletionHandler) handler
{
    NSArray *operations = @[
                            [NSBlockOperation blockOperationWithBlock:^{
                                [self refreshImageFolder:handler];
                            }],
                            [NSBlockOperation blockOperationWithBlock:^{
                                [self refreshCollection:@"sessions" handler:handler];
                            }],
                            [NSBlockOperation blockOperationWithBlock:^{
                                [self refreshCollection:@"speakers" handler:handler];
                            }],
                            [NSBlockOperation blockOperationWithBlock:^{
                                [self refreshCollection:@"surveys" handler:handler];
                            }],
                            [NSBlockOperation blockOperationWithBlock:^{
                                [self refreshCollection:@"sponsors" handler:handler];
                            }],
                            [NSBlockOperation blockOperationWithBlock:^{
                                [self refreshCollection:@"news" handler:handler];
                            }],
                            [NSBlockOperation blockOperationWithBlock:^{
                                [self refreshCollection:@"pages" handler:handler];
                            }]];
    for (NSOperation *operation in operations) {
        operation.queuePriority = NSOperationQueuePriorityVeryHigh;
        [self.downloadQueue addOperation:operation];
    }
}

- (void) refreshCollection:(NSString *) collectionName
                   handler:(ConnectionCompletionHandler)handler
{
    NSMutableURLRequest *queryRequest;
    if ([collectionName isEqualToString:@"news"]) {
        queryRequest = [self.usergrid getEntitiesInCollection:@"newsitems"
                                                   usingQuery:@{@"limit":@100,
                                                                @"ql":@"select * order by created desc"}];
    } else if ([collectionName isEqualToString:@"sponsors"]) {
        queryRequest = [self.usergrid getEntitiesInCollection:@"sponsors"
                                                   usingQuery:@{@"limit":@100,
                                                                @"ql":@"select * order by displayorder asc"}];
    } else {
        queryRequest = [self.usergrid getEntitiesInCollection:collectionName limit:100];
    }
    RadHTTPClient *client = [[RadHTTPClient alloc] initWithRequest:queryRequest];
    RadHTTPResult *result = [client connectSynchronously];
    if (result.statusCode == 200) {
        [[result data] writeToFile:[self fileNameForCollection:collectionName] atomically:YES];
        [self setValue:[[result object] objectForKey:@"entities"] forKey:collectionName];
        [self processCollection:collectionName];
    }
    if (handler) {
        handler([collectionName capitalizedString], result);
    }
}

- (NSString *) imageFolderName
{
    return [[Conference cacheDirectory] stringByAppendingPathComponent:@"images"];
}

- (void) refreshImageFolder:(ConnectionCompletionHandler) handler
{
    // ensure that a directory exists to store images
    [[NSFileManager defaultManager] createDirectoryAtPath:[self imageFolderName]
                              withIntermediateDirectories:YES
                                               attributes:nil
                                                    error:NULL];
    
    NSMutableURLRequest *queryRequest = [self.usergrid getEntitiesInCollection:@"assets" limit:200];
    RadHTTPClient *client = [[RadHTTPClient alloc] initWithRequest:queryRequest];
    RadHTTPResult *result = [client connectSynchronously];
    if (result.statusCode == 200) {
        [[result data] writeToFile:[self fileNameForCollection:@"assets"] atomically:YES];
        self.assets = [[result object] objectForKey:@"entities"];
        
        if (YES) {
            for (NSDictionary *asset in [[result object] objectForKey:@"entities"]) {
                
                NSString *fileName =
                [[[Conference cacheDirectory]
                  stringByAppendingPathComponent:@"images"]
                 stringByAppendingPathComponent:[asset objectForKey:@"path"]];
                NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:fileName
                                                                                            error:NULL];
                int remoteSize = [[[asset objectForKey:@"file-metadata"]
                                   objectForKey:@"content-length"]
                                  intValue];
                int localSize = [[attributes objectForKey:@"NSFileSize"] intValue];
                
                if (remoteSize == localSize) {
                    // we already have the file
                    // NSLog(@"we already have %@", [document objectForKey:@"Name"]);
                } else {
                    NSBlockOperation *operation = [NSBlockOperation blockOperationWithBlock:^{
                        // NSLog(@"prefetching image %@ BEGIN", [asset objectForKey:@"path"]);
                        NSMutableURLRequest *request = [self.usergrid
                                                        getDataForAsset:[asset objectForKey:@"uuid"]];
                        RadHTTPResult *result = [RadHTTPClient connectSynchronouslyWithRequest:request];
                        NSString *fileName = [[[Conference cacheDirectory]
                                               stringByAppendingPathComponent:@"images"]
                                              stringByAppendingPathComponent:[asset objectForKey:@"path"]];
                        if (result.statusCode == 200) {
                            // NSLog(@"writing to %@", fileName);
                            [[result data] writeToFile:fileName atomically:NO];
                        } else {
                            NSLog(@"RESPONSE %d %@", (int) result.statusCode, [result UTF8String]);
                        }
                    }];
                    operation.queuePriority = NSOperationQueuePriorityLow;
                    [self.downloadQueue addOperation:operation];
                }
            }
        }
    } else {
        NSLog(@"RESPONSE %d %@", (int) result.statusCode, [result UTF8String]);
    }
    if (handler) {
        handler(@"Images", result);
    }
}

- (void) fetchImageWithName:(NSString *) name
                 completion:(ImageFetchCompletionHandler) handler
{
    // if we can locate the image in the app bundle or the images folder, return it directly
    NSString *filename = name;
    NSString *imagePath = [[[Conference cacheDirectory]
                            stringByAppendingPathComponent:@"images"]
                           stringByAppendingPathComponent:filename];
    NSData *imageData = [NSData dataWithContentsOfFile:imagePath];
    UIImage *image = [UIImage imageWithData:imageData];
    if (!image) {
        image = [UIImage imageNamed:name];
    }
    if (image) {
        handler(image);
        return;
    }
    
    // otherwise, we try to download it
    for (NSDictionary *document in self.assets) {
        if ([name isEqualToString:[document objectForKey:@"path"]]) {
            NSBlockOperation *operation = [NSBlockOperation blockOperationWithBlock:^{
                DLog(@"fetching %@ BEGIN", document);
                NSMutableURLRequest *request = [self.usergrid getDataForAsset:[document objectForKey:@"uuid"]];
                RadHTTPResult *result = [RadHTTPClient connectSynchronouslyWithRequest:request];
                NSString *fileName =
                [[[Conference cacheDirectory]
                  stringByAppendingPathComponent:@"images"]
                 stringByAppendingPathComponent:[document objectForKey:@"path"]];
                if (result.statusCode == 200) {
                    DLog(@"got %@", fileName);
                    NSData *imageData = [result data];
                    [imageData writeToFile:fileName atomically:NO];
                    UIImage *image = [UIImage imageWithData:imageData];
                    handler(image);
                } else {
                    DLog(@"RESPONSE %d %@", (int) result.statusCode, [result UTF8String]);
                }
                DLog(@"fetching %@ END", name);
            }];
            operation.queuePriority = NSOperationQueuePriorityHigh;
            [self.downloadQueue addOperation:operation];
        }
    }
}

- (NSDictionary *) speakerWithId:(NSString *) speakerId
{
    for (id speaker in self.speakers) {
        if ([[speaker objectForKey:@"id"] isEqualToString:speakerId]) {
            return speaker;
        } else if ([[speaker objectForKey:@"uuid"] isEqualToString:speakerId]) {
            return speaker;
        }
    }
    return nil;
}

- (NSDictionary *) speakerWithName:(NSString *) speakerName
{
    for (id speaker in self.speakers) {
        if ([[speaker objectForKey:@"name"] isEqualToString:speakerName]) {
            return speaker;
        }
    }
    return nil;
}

- (NSDictionary *) sessionWithName:(NSString *)sessionName
{
    for (id session in self.sessions) {
        if ([[session objectForKey:@"name"] isEqualToString:sessionName]) {
            return session;
        }
    }
    return nil;
}

- (NSDictionary *) surveyWithName:(NSString *) name;
{
    for (id survey in self.surveys) {
        if ([[survey objectForKey:@"name"] isEqualToString:name]) {
            return survey;
        }
    }
    return nil;
}

- (NSDictionary *) newsItemWithName:(NSString *)name
{
    for (id newsItem in self.news) {
        if ([[newsItem objectForKey:@"name"] isEqualToString:name]) {
            return newsItem;
        }
    }
    return nil;
}

- (NSDictionary *) sponsorWithName:(NSString *)name
{
    for (id sponsor in self.sponsors) {
        if ([[sponsor objectForKey:@"name"] isEqualToString:name]) {
            return sponsor;
        }
    }
    return nil;
}

- (NSDictionary *) propertyWithName:(NSString *)name
{
    for (id property in self.properties) {
        if ([[property objectForKey:@"name"] isEqualToString:name]) {
            return property;
        }
    }
    return nil;
}

- (NSArray *) alphabetizedSpeakersForYear:(int) year
{
    return [self.alphabetizedSpeakers objectForKey:@(year)];
}

@end

