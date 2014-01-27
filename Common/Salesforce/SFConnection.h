//
//  SFConnection.h
//  #renio
//
//  Created by Tim Burks on 11/2/13.
//  Copyright (c) 2013 Radtastical Inc. All rights reserved.
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

@interface SFConnection : NSObject
@property (nonatomic, strong) NSString *consumerName;
@property (nonatomic, strong) NSString *consumerKey;
@property (nonatomic, strong) NSString *consumerSecret;
@property (nonatomic, strong) NSString *apiVersion;
@property (nonatomic, strong) NSString *accessToken;
@property (nonatomic, strong) NSString *instanceURLPath;

// Shared instance
+ (instancetype) sharedInstance;

// Configure the connection
- (void) setConsumerKey:(NSString *) consumerKey
              secret:(NSString *) consumerSecret;

// Discard authentication token to end a session
- (void) signOut;

// Use this to confirm that a connection has a usable access token.
- (BOOL) isAuthenticated;

// Return an NSMutableURLRequest that will perform an OAuth2 password-based signin
- (NSMutableURLRequest *) authenticateWithUsername:(NSString *) username
                                          password:(NSString *) password
                                     securityToken:(NSString *) securityToken;

// Authentication helper: call this method with the result of authentication request.
- (BOOL) finishAuthenticatingWithResponse:(NSURLResponse *) response
                                     data:(NSData *) data
                                    error:(NSError *) error;

// Authentication helper: the same as the above method, but sometimes it's easier to call this
- (BOOL) finishAuthenticatingWithResult:(RadHTTPResult *) result;

#if TARGET_OS_IPHONE
// Authenticate with OAuth
- (BOOL) authenticateWithSafariUsingCallbackPath:(NSString *) callbackPath;

// Authenticate with the KeyRing app-to-app protocol
- (BOOL) authenticateWithKeyRing;

// Final phase of OAuth/KeyRing app-to-app authentication
- (BOOL) finishAuthenticatingWithOAuthResponse:(NSDictionary *) response;
#endif

// Return an NSMutableURLRequest that will describe a database
- (NSMutableURLRequest *) describeDatabase;

// Return an NSMutableURLRequest that will describe a database type
- (NSMutableURLRequest *) describeDatabaseType:(NSString *) objectType;

// Return an NSMutableURLRequest that will perform a database query
- (NSMutableURLRequest *) queryRequestWithArguments:(NSDictionary *) arguments;

// Return an NSMutableURLRequest that will perform a database search
- (NSMutableURLRequest *) searchRequestWithArguments:(NSDictionary *)arguments;

// Return an NSMutableURLRequest that will create a database entry
- (NSMutableURLRequest *) createObjectWithType:(NSString *) objectType
                                        fields:(NSDictionary *) fields;

// Return an NSMutableURLRequest that will fetch a database entry
- (NSMutableURLRequest *) fetchObjectWithType:(NSString *) objectType
                                     objectId:(NSString *) objectId;

// Return an NSMutableURLRequest that will update a database entry
- (NSMutableURLRequest *) updateObjectWithType:(NSString *) objectType
                                      objectId:(NSString *) objectId
                                        fields:(NSDictionary *) fields;

// Return an NSMutableURLRequest that will delete an object
- (NSMutableURLRequest *) deleteObjectWithType:(NSString *) objectType
                                      objectId:(NSString *) objectId;

// Return an NSMutableURLRequest that will create a document in a folder
- (NSMutableURLRequest *) createDocumentWithName:(NSString *)name
                                     description:(NSString *)description
                                        folderId:(NSString *)folderId
                                        bodyData:(NSData *)bodyData;

// Return an NSMutableURLRequest that will fetch the body of a document
- (NSMutableURLRequest *) fetchBodyOfDocumentWithObjectId:(NSString *) documentId;

// Return an NSMutableURLRequest that will update a document in a folder
- (NSMutableURLRequest *) updateDocumentWithObjectId:(NSString *) objectId
                                                name:(NSString *) name
                                         description:(NSString *) description
                                            folderId:(NSString *) folderId
                                            bodyData:(NSData *) bodyData;

// Return an NSMutableURLRequest that will delete a document
- (NSMutableURLRequest *) deleteDocumentWithObjectId:(NSString *) objectId;

@end
