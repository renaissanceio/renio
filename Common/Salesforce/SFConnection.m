//
//  SFConnection.m
//  #renio
//
//  Created by Tim Burks on 11/2/13.
//  Copyright (c) 2013 Radtastical Inc. All rights reserved.
//

#import "SFConnection.h"
#import "RadHTTPHelpers.h"
#import "RadHTTPResult.h"
#import "RadBinaryEncoding.h"

@interface SFConnection ()
@end

@implementation SFConnection

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
        self.consumerName = @"iOS App";
        self.apiVersion = @"v24.0";
    }
    return self;
}

#pragma mark Authentication

- (void) setConsumerKey:(NSString *)consumerKey
                 secret:(NSString *)consumerSecret
{
    self.consumerKey = consumerKey;
    self.consumerSecret = consumerSecret;
    // clear authentication token
    self.accessToken = nil;
}

- (void) signOut
{
    self.accessToken = nil;
}

- (BOOL) isAuthenticated
{
    return self.accessToken != nil;
}

- (NSMutableURLRequest *) authenticateWithUsername:(NSString *) username
                                          password:(NSString *) password
                                     securityToken:(NSString *) securityToken
{
    assert(self.consumerName);
    assert(self.consumerKey);
    assert(self.consumerSecret);
    NSString *endpointPath = @"https://login.salesforce.com/services/oauth2/token";
    NSMutableString *fullPassword = [NSMutableString stringWithString:password];
    if (securityToken && [securityToken isKindOfClass:[NSString class]]) {
        [fullPassword appendString:securityToken];
    }
    NSDictionary *arguments =
    @{@"grant_type":@"password",
      @"client_id":self.consumerKey,
      @"client_secret":self.consumerSecret,
      @"username":username,
      @"password":fullPassword};
    NSURL *URL = [NSURL URLWithString:endpointPath];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:URL];
    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:[arguments rad_URLQueryData]];
    [request setValue:@"application/x-www-form-urlencoded"
   forHTTPHeaderField:@"Content-Type"];
    return request;
}

- (BOOL) finishAuthenticatingWithResponse:(NSHTTPURLResponse *) response
                                     data:(NSData *) data
                                    error:(NSError *) error;
{
    id results = [self objectForResponse:response data:data error:error];
    self.accessToken = results[@"access_token"];
    self.instanceURLPath = results[@"instance_url"];
    //NSLog(@"ACCESS TOKEN: %@", self.accessToken);
    //NSLog(@"INSTANCE URL: %@", self.instanceURLPath);
    return [self isAuthenticated];
}

- (BOOL) finishAuthenticatingWithResult:(RadHTTPResult *) result
{
    return [self finishAuthenticatingWithResponse:result.response data:result.data error:result.error];
}

#if TARGET_OS_IPHONE

- (BOOL) authenticateWithSafariUsingCallbackPath:(NSString *) callbackPath
{
    NSString *path = @"https://login.salesforce.com/services/oauth2/authorize?";
    
    NSDictionary *arguments = @{@"response_type":@"token",
                                @"client_id":self.consumerKey,
                                @"redirect_uri":callbackPath,
                                @"state":@"appistry"};
    path = [path stringByAppendingString:[arguments rad_URLQueryString]];
    NSURL *URL = [NSURL URLWithString:path];
    return [[UIApplication sharedApplication] openURL:URL];
}

- (BOOL) authenticateWithKeyRing
{
    NSDictionary *request =
    @{@"version":@"1.0",
      @"requester":@{@"scheme":@"browser",
                     @"name":self.consumerName,
                     @"consumer key":self.consumerKey,
                     @"consumer secret":self.consumerSecret}};
    NSError *error;
    NSData *requestData = [NSJSONSerialization dataWithJSONObject:request
                                                          options:0
                                                            error:&error];
    NSString *requestString = [[NSString alloc]
                               initWithData:requestData
                               encoding:NSUTF8StringEncoding];
    
    BOOL status = [[UIApplication sharedApplication] openURL:
                   [NSURL URLWithString:
                    [NSString stringWithFormat:@"keyring:?%@",
                     [@{@"request":requestString}
                      rad_URLQueryString]]]];
    return status;
}

- (BOOL) finishAuthenticatingWithOAuthResponse:(NSDictionary *)response
{
    self.accessToken = [response objectForKey:@"access_token"];
    self.instanceURLPath = [response objectForKey:@"instance_url"];
    return YES;
}

#endif

#pragma mark Helpers

- (id) objectForResponse:(NSHTTPURLResponse *) response
                    data:(NSData *) data
                   error:(NSError *) error
{
    if (!error) {
        NSString *contentType = [[response allHeaderFields] objectForKey:@"Content-Type"];
        if ([contentType isEqualToString:@"application/xml"]) {
            // assume the response data is a property list
            id object = [NSPropertyListSerialization propertyListWithData:data options:0 format:nil error:nil];
            NSLog(@"%@", [object description]);
            return object;
        } else {
            // otherwise let's assume we got JSON
            NSError *error;
            id object = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
            if (error) {
                NSLog(@"JSON ERROR: %@", [error description]);
            }
            return object;
        }
    } else {
        return nil;
    }
}

- (BOOL) signRequest:(NSMutableURLRequest *) request {
    if ([self isAuthenticated]) {
        [request setValue:[NSString stringWithFormat:@"Bearer %@", self.accessToken]
       forHTTPHeaderField:@"Authorization"];
        return YES;
    } else {
        return NO;
    }
}

#pragma mark Database operations

// Return an NSMutableURLRequest that will describe a database
- (NSMutableURLRequest *) describeDatabase
{
    NSString *servicePath = [NSString stringWithFormat:@"/services/data/%@/sobjects", self.apiVersion];
    NSString *path = [self.instanceURLPath stringByAppendingString:servicePath];
    NSURL *URL = [NSURL URLWithString:path];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:URL];
    return [self signRequest:request] ? request : nil;
}

// Return an NSMutableURLRequest that will describe a database type
- (NSMutableURLRequest *) describeDatabaseType:(NSString *)objectType
{
    NSString *servicePath = [NSString stringWithFormat:@"/services/data/%@/sobjects/%@/describe",
                             self.apiVersion,
                             objectType];
    NSString *path = [self.instanceURLPath stringByAppendingString:servicePath];
    NSURL *URL = [NSURL URLWithString:path];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:URL];
    return [self signRequest:request] ? request : nil;
}

- (NSMutableURLRequest *) queryRequestWithArguments:(NSDictionary *)arguments
{
    NSString *servicePath = [NSString stringWithFormat:@"/services/data/%@/query?", self.apiVersion];
    NSString *path = [[self.instanceURLPath
                       stringByAppendingString:servicePath]
                      stringByAppendingString:[arguments rad_URLQueryString]];
    NSURL *URL = [NSURL URLWithString:path];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:URL];
    return [self signRequest:request] ? request : nil;
}

- (NSMutableURLRequest *) searchRequestWithArguments:(NSDictionary *)arguments
{
    NSString *servicePath = [NSString stringWithFormat:@"/services/data/%@/search?", self.apiVersion];
    NSString *path = [[self.instanceURLPath
                       stringByAppendingString:servicePath]
                      stringByAppendingString:[arguments rad_URLQueryString]];
    NSURL *URL = [NSURL URLWithString:path];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:URL];
    return [self signRequest:request] ? request : nil;
}

- (NSMutableURLRequest *) createObjectWithType:(NSString *) objectType
                                        fields:(NSDictionary *) fields
{
    NSString *path = [NSString stringWithFormat:@"%@/services/data/%@/sobjects/%@",
                      self.instanceURLPath,
                      self.apiVersion,
                      objectType];
    NSURL *URL = [NSURL URLWithString:path];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:URL];
    [request setHTTPMethod:@"POST"];
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:fields options:0 error:NULL];
    [request setHTTPBody:jsonData];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    return [self signRequest:request] ? request : nil;
}

- (NSMutableURLRequest *) fetchObjectWithType:(NSString *)objectType
                                     objectId:(NSString *)objectId
{
    NSString *path = [NSString stringWithFormat:@"%@/services/data/%@/sobjects/%@/%@",
                      self.instanceURLPath,
                      self.apiVersion,
                      objectType,
                      objectId];
    NSURL *URL = [NSURL URLWithString:path];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:URL];
    return [self signRequest:request] ? request : nil;
}

- (NSMutableURLRequest *) updateObjectWithType:(NSString *)objectType
                                      objectId:(NSString *)objectId
                                        fields:(NSDictionary *)fields
{
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:fields options:0 error:NULL];
    
    NSString *servicePath = [NSString stringWithFormat:@"/services/data/%@/sobjects", self.apiVersion];
    NSDictionary *arguments = @{@"_HttpMethod":@"PATCH"};
    NSString *path = [NSString stringWithFormat:@"%@%@/%@/%@/?%@",
                      self.instanceURLPath,
                      servicePath,
                      objectType,
                      objectId,
                      [arguments rad_URLQueryString]];
    NSURL *URL = [NSURL URLWithString:path];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:URL];
    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:jsonData];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    return [self signRequest:request] ? request : nil;
}

- (NSMutableURLRequest *) deleteObjectWithType:(NSString *)objectType
                                      objectId:(NSString *)objectId
{
    NSString *path = [NSString stringWithFormat:@"%@/services/data/%@/sobjects/%@/%@",
                      self.instanceURLPath,
                      self.apiVersion,
                      objectType,
                      objectId];
    NSURL *URL = [NSURL URLWithString:path];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:URL];
    [request setHTTPMethod:@"DELETE"];
    return [self signRequest:request] ? request : nil;
}

- (NSMutableURLRequest *) createDocumentWithName:(NSString *)name
                                     description:(NSString *)description
                                        folderId:(NSString *)folderId
                                        bodyData:(NSData *)bodyData
{
    NSDictionary *fields = @{@"Name":name,
                             @"FolderId":folderId,
                             @"Description":description,
                             @"Body":[bodyData rad_base64EncodedString]};
    return [self createObjectWithType:@"Document" fields:fields];
}

- (NSMutableURLRequest *) fetchBodyOfDocumentWithObjectId:(NSString *) documentId
{
    NSString *path = [NSString stringWithFormat:@"%@/services/data/%@/sobjects/Document/%@/Body",
                      self.instanceURLPath,
                      self.apiVersion,
                      documentId];
    NSURL *URL = [NSURL URLWithString:path];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:URL];
    return [self signRequest:request] ? request : nil;
}

- (NSMutableURLRequest *) updateDocumentWithObjectId:(NSString *) objectId
                                                name:(NSString *) name
                                         description:(NSString *) description
                                            folderId:(NSString *) folderId
                                            bodyData:(NSData *) bodyData
{
    NSDictionary *fields = @{@"Name":name,
                             @"FolderId":folderId,
                             @"Description":description,
                             @"Body":[bodyData rad_base64EncodedString]};
    return [self updateObjectWithType:@"Document"
                             objectId:objectId
                               fields:fields];
}

- (NSMutableURLRequest *) deleteDocumentWithObjectId:(NSString *)objectId
{
    return [self deleteObjectWithType:@"Document" objectId:objectId];
}

@end
