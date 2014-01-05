#import <Foundation/Foundation.h>

@class RadHTTPResult;

typedef void (^RadHTTPCompletionHandler)(RadHTTPResult *result);

@interface RadHTTPClient : NSObject

@property (nonatomic, strong) RadHTTPCompletionHandler completionHandler;

+ (RadHTTPClient *) connectWithRequest:(NSMutableURLRequest *) request
                     completionHandler:(RadHTTPCompletionHandler) completionHandler;

+ (RadHTTPResult *) connectSynchronouslyWithRequest:(NSMutableURLRequest *) request;

- (id) initWithRequest:(NSMutableURLRequest *) request;

- (void) connectWithCompletionHandler:(RadHTTPCompletionHandler) completionHandler;

- (RadHTTPResult *) connectSynchronously;

@end
