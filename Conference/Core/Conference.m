//
//  Conference.m
//  #renio
//
//  Created by Tim Burks on 11/4/13.
//  Copyright (c) 2013 Radtastical Inc Inc. All rights reserved.
//

#import "Conference.h"
#import "UGConnection.h"
#import "RadHTTP.h"
#import "RadRequestRouter.h"

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
        self.usergrid.organization = @"radtastical";
        self.usergrid.application = @"renaissance";
        
        self.downloadQueue = [[NSOperationQueue alloc] init];
        [self.downloadQueue setMaxConcurrentOperationCount:2];
        
        [self loadPagesFromFile];
        [self loadSessionsFromFile];
        [self loadSpeakersFromFile];
        [self loadNewsFromFile];
        [self loadSurveysFromFile];
        [self loadSponsorsFromFile];
        [self loadPropertiesFromFile];
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

- (void) loadSessionsFromFile
{
    NSData *data = [NSData dataWithContentsOfFile:[self fileNameForCollection:@"sessions"]];
    if (data) {
        id object = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        self.sessions = [object objectForKey:@"entities"];
    }
    [self processSessions];
}

- (void) loadSpeakersFromFile
{
    NSData *data = [NSData dataWithContentsOfFile:[self fileNameForCollection:@"speakers"]];
    if (data) {
        id object = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        self.speakers = [object objectForKey:@"entities"];
    }
    [self processSpeakers];
}

- (void) loadPagesFromFile
{
    NSData *data = [NSData dataWithContentsOfFile:[self fileNameForCollection:@"pages"]];
    if (data) {
        id object = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        self.pages = [object objectForKey:@"entities"];
    }
    [self processPages];
}

- (void) loadSponsorsFromFile
{
    NSData *data = [NSData dataWithContentsOfFile:[self fileNameForCollection:@"sponsors"]];
    if (data) {
        id object = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        self.sponsors = [object objectForKey:@"entities"];
    }
}

- (void) loadPropertiesFromFile
{
    NSData *data = [NSData dataWithContentsOfFile:[self fileNameForCollection:@"properties"]];
    if (data) {
        id object = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        self.properties = [object objectForKey:@"entities"];
    }
}

- (void) loadNewsFromFile
{
    NSData *data = [NSData dataWithContentsOfFile:[self fileNameForCollection:@"news"]];
    if (data) {
        id object = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        self.news = [object objectForKey:@"entities"];
    }
}

- (void) loadSurveysFromFile
{
    NSData *data = [NSData dataWithContentsOfFile:[self fileNameForCollection:@"surveys"]];
    if (data) {
        id object = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        self.surveys = [object objectForKey:@"entities"];
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

- (NSArray *) alphabetizedSpeakersForYear:(int) year
{
    return [self.alphabetizedSpeakers objectForKey:@(year)];
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
    [RadHTTPClient connectWithRequest:
     [self.usergrid getAccessTokenForApplicationWithUsername:@"wemakeapps"
                                                    password:@"renaissanceio"]
                    completionHandler:^(RadHTTPResult *result) {
                        if (result.statusCode == 200) {
                            [self.usergrid authenticateWithResult:result];
                            
                            [RadHTTPClient connectWithRequest:
                             [self.usergrid getEntitiesInCollection:@"properties" limit:100]
                                            completionHandler:^(RadHTTPResult *result) {
                                                if (result.statusCode == 200) {
                                                    [[result data] writeToFile:[self fileNameForCollection:@"properties"]
                                                                    atomically:YES];
                                                    self.properties = [[result object] objectForKey:@"entities"];
                                                    handler(@"Done");
                                                } else {
                                                    errorHandler(result);
                                                }
                                            }];
                        } else {
                            errorHandler(result);
                        }
                    }];
}

- (void) refreshConferenceWithCompletionHandler:(ConnectionCompletionHandler) handler
{
    NSArray *operations = @[
                            [NSBlockOperation blockOperationWithBlock:^{
                                [self refreshSessionList:handler];
                            }],
                            [NSBlockOperation blockOperationWithBlock:^{
                                [self refreshSpeakerList:handler];
                            }],
                            [NSBlockOperation blockOperationWithBlock:^{
                                [self refreshSurveys:handler];
                            }],
                            [NSBlockOperation blockOperationWithBlock:^{
                                [self refreshSponsors:handler];
                            }],
                            [NSBlockOperation blockOperationWithBlock:^{
                                [self refreshNews:handler];
                            }],
                            [NSBlockOperation blockOperationWithBlock:^{
                                [self refreshImageFolder:handler];
                            }],
                            [NSBlockOperation blockOperationWithBlock:^{
                                [self refreshPages:handler];
                            }]];
    for (NSOperation *operation in operations) {
        operation.queuePriority = NSOperationQueuePriorityVeryHigh;
        [self.downloadQueue addOperation:operation];
    }
}

- (void) refreshSessionList:(ConnectionCompletionHandler)handler
{
    NSMutableURLRequest *queryRequest = [self.usergrid getEntitiesInCollection:@"sessions" limit:100];
    RadHTTPClient *client = [[RadHTTPClient alloc] initWithRequest:queryRequest];
    RadHTTPResult *result = [client connectSynchronously];
    if (result.statusCode == 200) {
        [[result data] writeToFile:[self fileNameForCollection:@"sessions"] atomically:YES];
        self.sessions = [[result object] objectForKey:@"entities"];
        [self processSessions];
    } else {
        NSLog(@"RESPONSE %d %@", (int) result.statusCode, [result UTF8String]);
    }
    if (handler) {
        handler(@"Sessions");
    }
}

- (void) refreshSpeakerList:(ConnectionCompletionHandler)handler
{
    NSMutableURLRequest *queryRequest = [self.usergrid getEntitiesInCollection:@"speakers" limit:100];
    RadHTTPClient *client = [[RadHTTPClient alloc] initWithRequest:queryRequest];
    RadHTTPResult *result = [client connectSynchronously];
    if (result.statusCode == 200) {
        [[result data] writeToFile:[self fileNameForCollection:@"speakers"] atomically:YES];
        self.speakers = [[result object] objectForKey:@"entities"];
        [self processSpeakers];
    } else {
        NSLog(@"RESPONSE %d %@", (int) result.statusCode, [result UTF8String]);
    }
    if (handler) {
        handler(@"Speakers");
    }
}

- (void) refreshSponsors:(ConnectionCompletionHandler) handler
{
    NSMutableURLRequest *queryRequest = [self.usergrid getEntitiesInCollection:@"sponsors" limit:100];
    RadHTTPClient *client = [[RadHTTPClient alloc] initWithRequest:queryRequest];
    RadHTTPResult *result = [client connectSynchronously];
    if (result.statusCode == 200) {
        [[result data] writeToFile:[self fileNameForCollection:@"sponsors"] atomically:YES];
        self.sponsors = [[result object] objectForKey:@"entities"];
    } else {
        NSLog(@"RESPONSE %d %@", (int) result.statusCode, [result UTF8String]);
    }
    if (handler) {
        handler(@"Sponsors");
    }
}

- (void) refreshPages:(ConnectionCompletionHandler) handler
{
    NSMutableURLRequest *queryRequest = [self.usergrid getEntitiesInCollection:@"pages" limit:100];
    RadHTTPClient *client = [[RadHTTPClient alloc] initWithRequest:queryRequest];
    RadHTTPResult *result = [client connectSynchronously];
    if (result.statusCode == 200) {
        [[result data] writeToFile:[self fileNameForCollection:@"pages"] atomically:YES];
        self.pages = [[result object] objectForKey:@"entities"];
        [self processPages];
    } else {
        NSLog(@"RESPONSE %d %@", (int) result.statusCode, [result UTF8String]);
    }
    if (handler) {
        handler(@"Pages");
    }
}

- (void) refreshNews:(ConnectionCompletionHandler) handler
{
    NSMutableURLRequest *queryRequest = [self.usergrid getEntitiesInCollection:@"newsitems" limit:100];
    RadHTTPClient *client = [[RadHTTPClient alloc] initWithRequest:queryRequest];
    RadHTTPResult *result = [client connectSynchronously];
    if (result.statusCode == 200) {
        [[result data] writeToFile:[self fileNameForCollection:@"news"] atomically:YES];
        self.news = [[result object] objectForKey:@"entities"];
    } else {
        NSLog(@"RESPONSE %d %@", (int) result.statusCode, [result UTF8String]);
    }
    if (handler) {
        handler(@"News");
    }
}

- (void) refreshImageFolder:(ConnectionCompletionHandler) handler
{
    [[NSFileManager defaultManager]
     createDirectoryAtPath:
     [[Conference cacheDirectory] stringByAppendingPathComponent:@"images"]
     withIntermediateDirectories:YES attributes:nil error:NULL];
    
    NSMutableURLRequest *queryRequest = [self.usergrid getEntitiesInCollection:@"assets" limit:100];
    RadHTTPClient *client = [[RadHTTPClient alloc] initWithRequest:queryRequest];
    RadHTTPResult *result = [client connectSynchronously];
    if (result.statusCode == 200) {
        [[result data] writeToFile:[self fileNameForCollection:@"documents"] atomically:YES];
        self.documents = [[result object] objectForKey:@"entities"];
        
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
        handler(@"Images");
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
    for (NSDictionary *document in self.documents) {
        if ([name isEqualToString:[document objectForKey:@"path"]]) {
            NSBlockOperation *operation = [NSBlockOperation blockOperationWithBlock:^{
                // NSLog(@"fetching %@ BEGIN", document);
                NSMutableURLRequest *request = [self.usergrid getDataForAsset:[document objectForKey:@"uuid"]];
                RadHTTPResult *result = [RadHTTPClient connectSynchronouslyWithRequest:request];
                NSString *fileName =
                [[[Conference cacheDirectory]
                  stringByAppendingPathComponent:@"images"]
                 stringByAppendingPathComponent:[document objectForKey:@"path"]];
                if (result.statusCode == 200) {
                    // NSLog(@"got %@", fileName);
                    NSData *imageData = [result data];
                    [imageData writeToFile:fileName atomically:NO];
                    UIImage *image = [UIImage imageWithData:imageData];
                    handler(image);
                } else {
                    NSLog(@"RESPONSE %d %@", (int) result.statusCode, [result UTF8String]);
                }
                //NSLog(@"fetching %@ END", name);
            }];
            operation.queuePriority = NSOperationQueuePriorityHigh;
            [self.downloadQueue addOperation:operation];
        }
    }
}

- (void) refreshSurveys:(ConnectionCompletionHandler) handler {
    NSMutableURLRequest *queryRequest = [self.usergrid getEntitiesInCollection:@"surveys" limit:100];
    RadHTTPClient *client = [[RadHTTPClient alloc] initWithRequest:queryRequest];
    RadHTTPResult *result = [client connectSynchronously];
    if (result.statusCode == 200) {
        [[result data] writeToFile:[self fileNameForCollection:@"surveys"] atomically:YES];
        self.surveys = [[result object] objectForKey:@"entities"];
    } else {
        NSLog(@"RESPONSE %d %@", (int) result.statusCode, [result UTF8String]);
    }
    if (handler) {
        handler(@"Surveys");
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


@end

