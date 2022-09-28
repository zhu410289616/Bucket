//
//  CCDDamURLProtocol.m
//  Pods
//
//  Created by zhuruhong on 2022/9/11.
//

#import "CCDDamURLProtocol.h"
#import "CCDDamServer.h"
#import "NSURLRequest+CCDDam.h"
#import "CCDLogger.h"

@interface CCDDamURLProtocol () <NSURLSessionTaskDelegate>

@property (nonatomic, strong) NSURLSessionDataTask *dataTask;

@end

@implementation CCDDamURLProtocol

+ (BOOL)canInitWithRequest:(NSURLRequest *)request
{
    return [[CCDDamServer sharedInstance] shouldHttpInterrupt:request];
}

+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request
{
    return [[CCDDamServer sharedInstance] canonicalRequest:request];
}

- (void)dealloc
{
    DDLogDebug(@"[dealloc] %@", self.class);
}

- (void)startLoading
{
    NSURLSessionConfiguration *configuration =
    [NSURLSessionConfiguration defaultSessionConfiguration];
    configuration.timeoutIntervalForRequest = 15;
    
    /**
     *  Create the session for this task
     *  We send nil as delegate queue so that the session creates a serial operation queue for performing all delegate
     *  method calls and completion handler calls.
     */
    NSURLSession *session =
    [NSURLSession sessionWithConfiguration:configuration delegate:self delegateQueue:nil];
    
    self.dataTask = [session dataTaskWithRequest:self.request];
    [self.dataTask resume];
}

- (void)stopLoading
{
    [self.dataTask cancel];
}

#pragma mark - NSURLSessionTaskDelegate

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler
{
    [[self client] URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageNotAllowed];
    completionHandler(NSURLSessionResponseAllow);
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask
    didReceiveData:(NSData *)data
{
    [self.client URLProtocol:self didLoadData:data];
    NSURLRequest *request = dataTask.originalRequest;
    DDLogInfo(@"[received]:%@:%@:%@", [request ccd_MD5], request.HTTPMethod, data);
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error
{
    if (!error) {
        [self.client URLProtocolDidFinishLoading:self];
    } else {
        [self.client URLProtocol:self didFailWithError:error];
    }
    NSURLRequest *request = task.originalRequest;
    DDLogInfo(@"[finished]:%@:%@", [request ccd_MD5], request.HTTPMethod);
    /// [NSURLSession sessionWithConfiguration:configuration delegate:self delegateQueue:self.sessionDelegateQueue] 中的 delegate 会被持有，
    /// 出现对象无法释放，session 请求完成后需要手动释放；
    [session finishTasksAndInvalidate];
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task willPerformHTTPRedirection:(NSHTTPURLResponse *)response newRequest:(NSURLRequest *)request completionHandler:(void (^)(NSURLRequest * _Nullable))completionHandler
{
    if (response != nil) {
        [[self client] URLProtocol:self wasRedirectedToRequest:request redirectResponse:response];
    }
}

/// 关于HTTPS证书验证逻辑
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential * __nullable credential))completionHandler
{
    if (!challenge) {
        return;
    }
    NSURLSessionAuthChallengeDisposition disposition = NSURLSessionAuthChallengePerformDefaultHandling;
    NSURLCredential *credential = nil;
    
    NSString* host = [[self.request allHTTPHeaderFields] objectForKey:@"host"];
    if (!host) {
        host = self.request.URL.host;
    }
    if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {
        if ([self evaluateServerTrust:challenge.protectionSpace.serverTrust forDomain:host]) {
            disposition = NSURLSessionAuthChallengeUseCredential;
            credential = [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust];
        } else {
            disposition = NSURLSessionAuthChallengePerformDefaultHandling;
        }
    } else {
        disposition = NSURLSessionAuthChallengePerformDefaultHandling;
    }
    completionHandler(disposition, credential);
}

- (BOOL)evaluateServerTrust:(SecTrustRef)serverTrust forDomain:(NSString *)domain
{
    NSMutableArray *policies = [NSMutableArray array];
    if (domain) {
        [policies addObject:(__bridge_transfer id) SecPolicyCreateSSL(true, (__bridge CFStringRef) domain)];
    } else {
        [policies addObject:(__bridge_transfer id) SecPolicyCreateBasicX509()];
    }
    
    SecTrustSetPolicies(serverTrust, (__bridge CFArrayRef) policies);

    SecTrustResultType result;
    SecTrustEvaluate(serverTrust, &result);
    if (result == kSecTrustResultUnspecified || result == kSecTrustResultProceed) {
        return YES;
    }
    return NO;
}

@end
