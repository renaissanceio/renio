#import "RadHTTPClient.h"
#import "RadHTTPResult.h"

@interface RadHTTPClient ()
@property (nonatomic, strong) NSMutableURLRequest *request;
@property (nonatomic, strong) NSMutableData *data;
@property (nonatomic, strong) NSHTTPURLResponse *response;
@property (nonatomic, strong) NSURLConnection *connection;
@end

@implementation RadHTTPClient

static int activityCount = 0;

+ (void) retainNetworkActivityIndicator {
    activityCount++;
#if TARGET_OS_IPHONE
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
#endif
}

+ (void) releaseNetworkActivityIndicator {
    activityCount--;
#if TARGET_OS_IPHONE
    if (activityCount == 0) {
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    }
#endif
}

+ (RadHTTPClient *) connectWithRequest:(NSMutableURLRequest *) request
                     completionHandler:(RadHTTPCompletionHandler) completionHandler
{
    RadHTTPClient *client = [[RadHTTPClient alloc] initWithRequest:request];
    [client connectWithCompletionHandler:completionHandler];
    return client;
}

+ (RadHTTPResult *) connectSynchronouslyWithRequest:(NSMutableURLRequest *) request
{
    RadHTTPClient *client = [[RadHTTPClient alloc] initWithRequest:request];
    return [client connectSynchronously];
}

- (id) initWithRequest:(NSMutableURLRequest *)request
{
    if (self = [super init]) {
        self.request = request;
    }
    //NSLog(@"Client Hello");
    return self;
}

- (void) dealloc
{
    //NSLog(@"Client Goodbye");
}

- (void) connectWithCompletionHandler:(RadHTTPCompletionHandler) completionHandler
{
    [RadHTTPClient retainNetworkActivityIndicator];
    NSURLSessionDataTask *task =
    [[NSURLSession sharedSession]
     dataTaskWithRequest:self.request
     completionHandler:
     ^(NSData *data, NSURLResponse *response, NSError *error) {
         dispatch_async(dispatch_get_main_queue(),
                        ^{
                            [RadHTTPClient releaseNetworkActivityIndicator];
                            RadHTTPResult *result = [[RadHTTPResult alloc]
                                                     initWithData:data
                                                     response:(NSHTTPURLResponse *)response
                                                     error:error];
                            if (completionHandler) {
                                completionHandler(result);
                            }
                        });
     }];
    // NSLog(@"task state %d", task.state);
    [task resume];
}

- (RadHTTPResult *) connectSynchronously
{
    dispatch_async(dispatch_get_main_queue(),^{[RadHTTPClient retainNetworkActivityIndicator];});
    NSError *error;
    NSHTTPURLResponse *response;
    NSData *data = [NSURLConnection sendSynchronousRequest:self.request
                                         returningResponse:&response
                                                     error:&error];
    dispatch_async(dispatch_get_main_queue(),^{[RadHTTPClient releaseNetworkActivityIndicator];});
    return [[RadHTTPResult alloc] initWithData:data response:response error:error];
}
@end
