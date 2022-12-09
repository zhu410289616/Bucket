//
//  CCDDamServer.h
//  Pods
//
//  Created by zhuruhong on 2022/9/11.
//

#import <Foundation/Foundation.h>

FOUNDATION_EXPORT NSString * const kCCDDamURLProtocolHandledKey;

typedef BOOL(^CCDDamHttpInterruptBlock)(NSURLRequest *request);

@interface CCDDamHandler : NSObject

@property (nonatomic, copy, readonly) CCDDamHttpInterruptBlock interruptBlock;

- (instancetype)initWithHttpInterruptBlock:(CCDDamHttpInterruptBlock)interruptBlock;

@end

@interface CCDDamServer : NSObject

/// 本地代理服务器端口，默认 20229；
@property (nonatomic, assign) NSInteger port;
/// web log server 是否运行中
@property (nonatomic, assign, readonly) BOOL isRunning;
/// server URL
@property (nonatomic, strong) NSURL *serverURL;

+ (instancetype)sharedInstance;

- (void)setEnabled:(BOOL)enabled;

- (void)start;
- (void)stop;

@end

@interface CCDDamServer (SessionConfiguration)

/// swizzle NSURLSessionConfiguration's protocolClasses method
- (void)load;
/// make NSURLSessionConfiguration's protocolClasses method is normal
- (void)unload;

@end

@interface CCDDamServer (Handler)

- (void)addHandler:(CCDDamHandler *)handler;
- (void)addHandlerWith:(CCDDamHttpInterruptBlock)httpInterruptBlock;
- (void)removeHandler:(CCDDamHandler *)handler;
- (void)removeAllHandlers;

@end

@interface CCDDamServer (HTTP)

- (BOOL)shouldHttpInterrupt:(NSURLRequest *)request;
- (NSURLRequest *)canonicalRequest:(NSURLRequest *)request;

@end
