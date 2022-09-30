//
//  CCDDamServer.m
//  Pods
//
//  Created by zhuruhong on 2022/9/11.
//

#import "CCDDamServer.h"
#import <objc/runtime.h>
#import "CCDDamURLProtocol.h"
#import "NSURLRequest+CCDDam.h"
#import "CCDLogger.h"
#import "CCDBucket.h"
#import <GCDWebServer/GCDWebServerPrivate.h>
#import <GCDWebServer/GCDWebSocketServer.h>
#import <GCDWebServer/GCDWebSocketServerConnection.h>

NSString * const kCCDDamURLProtocolHandledKey = @"kCCDDamURLProtocolHandledKey";

@interface CCDDamHandler ()

@property (nonatomic, copy) CCDDamHttpInterruptBlock interruptBlock;

@end

@implementation CCDDamHandler

- (instancetype)initWithHttpInterruptBlock:(CCDDamHttpInterruptBlock)interruptBlock
{
    if (self = [super init]) {
        _interruptBlock = interruptBlock;
    }
    return self;
}

@end

#pragma mark -

@interface CCDDamServer ()
<
GCDWebServerDelegate,
GCDWebSocketServerTransport,
CCDBucketSubscriber
>

@property (nonatomic, assign) BOOL enabled;
@property (nonatomic, strong) NSMutableArray<CCDDamHandler *> *handlers;

@property (nonatomic, strong) GCDWebSocketServer *webServer;
@property (nonatomic, strong) NSMutableArray *logConnections;

@end

@implementation CCDDamServer

+ (instancetype)sharedInstance
{
    static id sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _port = 20229;
        _handlers = @[].mutableCopy;
        _logConnections = @[].mutableCopy;
    }
    return self;
}

#pragma mark - getter & setter

- (void)setEnabled:(BOOL)enabled
{
    @synchronized (self) {
        _enabled = enabled;
        if (enabled) {
            [NSURLProtocol registerClass:[CCDDamURLProtocol class]];
            [self load];
        } else {
            [NSURLProtocol unregisterClass:[CCDDamURLProtocol class]];
            [self unload];
        }
    }
}

#pragma mark -

- (void)start
{
    [[CCDBucket sharedInstance] addObserver:self];
    [self startWebSocketServer];
}

- (void)stop
{
    [[CCDBucket sharedInstance] removeObserver:self];
    [self.webServer stop];
}

#pragma mark - websocket server

- (NSString *)pathForResource:(NSString *)resource ofType:(NSString *)type inBundle:(NSString *)bundleName
{
    NSString *tmpBundleName = bundleName;
    if (tmpBundleName.length && ![tmpBundleName hasSuffix:@".bundle"]) {
        tmpBundleName = [NSString stringWithFormat:@"%@.bundle", tmpBundleName];
    }
    
    NSString *mainBundlePath = NSBundle.mainBundle.resourcePath;
    NSString *localBundlePath = [mainBundlePath stringByAppendingPathComponent:tmpBundleName];
    NSBundle *localBundle = [NSBundle bundleWithPath:localBundlePath];
    NSString *path = [localBundle pathForResource:resource ofType:type];
    return path;
}

- (void)startWebSocketServer
{
    //websocket log
    NSError *error;
    NSString *path = [self pathForResource:@"log" ofType:@"html" inBundle:@"CCDDamServer.bundle"];
    NSString *wsPage = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&error];
    
    GCDWebSocketServer *wsServer = [[GCDWebSocketServer alloc] init];
    wsServer.transport = self;
    self.webServer = wsServer;
    self.webServer.delegate = self;
    __weak typeof(self) weakSelf = self;
    [self.webServer addHandlerForMethod:@"GET" path:@"/log" requestClass:[GCDWebServerRequest class] processBlock:^GCDWebServerResponse * _Nullable(__kindof GCDWebServerRequest * _Nonnull request) {
        __strong typeof(self) strongSelf = weakSelf;
        NSString *host = strongSelf.webServer.serverURL ? strongSelf.webServer.serverURL.host : strongSelf.webServer.bonjourServerURL.host;
        NSNumber *port = @(strongSelf.port);
        NSString *html = [NSString stringWithFormat:wsPage, host, port];
        return [GCDWebServerDataResponse responseWithHTML:html];
    }];
    
    if ([self.webServer startWithPort:self.port bonjourName:nil]) {
        DDLogInfo(@"[DamServer] start on %@", @(self.port));
    } else {
        DDLogInfo(@"[DamServer] start fail");
    }
}

#pragma mark - GCDWebServerDelegate

/**
 *  This method is called after the server has successfully started.
 */
- (void)webServerDidStart:(GCDWebServer*)server
{
    DDLogDebug(@"[WebServer] start: %@", server.serverURL);
}

- (void)webServerDidCompleteBonjourRegistration:(GCDWebServer*)server
{
    DDLogDebug(@"[WebServer] Bonjour: %@", server.bonjourServerURL);
}

- (void)webServerDidStop:(GCDWebServer*)server
{
    DDLogDebug(@"[WebServer] stop: %@", server);
}

#pragma mark - GCDWebSocketServerTransport

- (void)transportWillStart:(GCDWebServerConnection *)transport
{
    if ([transport isKindOfClass:[GCDWebSocketServerConnection class]]) {
        [self.logConnections addObject:transport];
    }
}

- (void)transportWillEnd:(GCDWebServerConnection *)transport
{
    if ([transport isKindOfClass:[GCDWebSocketServerConnection class]]) {
        [self.logConnections removeObject:transport];
    }
}

- (void)transport:(GCDWebServerConnection *)transport received:(GCDWebSocketMessage)msg
{
    DDLogDebug(@"[received] opcode: %d, payload: %@", msg.header.opcode, msg.body.payload);
    
#ifdef DEBUG
    GCDWebSocketServerConnection *connection = nil;
    if ([transport isKindOfClass:[GCDWebSocketServerConnection class]]) {
        connection = (GCDWebSocketServerConnection *)transport;
    }
    
    //echo message
    GCDWebSocketMessage echoMessage;
    echoMessage.header.fin = YES;
    echoMessage.header.opcode = GCDWebSocketOpcodeTextFrame;
    echoMessage.body.payload = msg.body.payload;
    [connection sendMessage:echoMessage];
#endif
}

#pragma mark - CCDBucketSubscriber

- (void)logWith:(NSString *)tag log:(NSString *)log
{
    NSString *tempStr = [NSString stringWithFormat:@"[%@]%@", tag, log];
    
    NSArray<GCDWebSocketServerConnection *> *cons = [self.logConnections copy];
    [cons enumerateObjectsUsingBlock:^(GCDWebSocketServerConnection * _Nonnull connection, NSUInteger idx, BOOL * _Nonnull stop) {
        //log message
        GCDWebSocketMessage echoMessage;
        echoMessage.header.fin = YES;
        echoMessage.header.opcode = GCDWebSocketOpcodeTextFrame;
        echoMessage.body.payload = [tempStr dataUsingEncoding:NSUTF8StringEncoding];
        [connection sendMessage:echoMessage];
    }];
}

- (void)trackWith:(NSString *)event params:(NSDictionary *)params
{
    NSString *tempStr = [NSString stringWithFormat:@"[%@]%@", event, params];
    
    NSArray<GCDWebSocketServerConnection *> *cons = [self.logConnections copy];
    [cons enumerateObjectsUsingBlock:^(GCDWebSocketServerConnection * _Nonnull connection, NSUInteger idx, BOOL * _Nonnull stop) {
        //log message
        GCDWebSocketMessage echoMessage;
        echoMessage.header.fin = YES;
        echoMessage.header.opcode = GCDWebSocketOpcodeTextFrame;
        echoMessage.body.payload = [tempStr dataUsingEncoding:NSUTF8StringEncoding];
        [connection sendMessage:echoMessage];
    }];
}

@end

@implementation CCDDamServer (SessionConfiguration)

- (void)load
{
    Class cls = NSClassFromString(@"__NSCFURLSessionConfiguration") ?: NSClassFromString(@"NSURLSessionConfiguration");
    [self swizzleSelector:@selector(protocolClasses) fromClass:cls toClass:[self class]];
}

- (void)unload
{
    Class cls = NSClassFromString(@"__NSCFURLSessionConfiguration") ?: NSClassFromString(@"NSURLSessionConfiguration");
    [self swizzleSelector:@selector(protocolClasses) fromClass:cls toClass:[self class]];
}

- (void)swizzleSelector:(SEL)selector fromClass:(Class)original toClass:(Class)stub
{
    Method originalMethod = class_getInstanceMethod(original, selector);
    Method stubMethod = class_getInstanceMethod(stub, selector);
    if (!originalMethod || !stubMethod) {
        [NSException raise:NSInternalInconsistencyException format:@"Couldn't load NEURLSessionConfiguration."];
    }
    method_exchangeImplementations(originalMethod, stubMethod);
}

- (NSArray *)protocolClasses
{
    // 如果还有其他的监控protocol，也可以在这里加进去
    return @[[CCDDamURLProtocol class]];
}

@end

@implementation CCDDamServer (Handler)

- (void)addHandler:(CCDDamHandler *)handler
{
    @synchronized (_handlers) {
        [_handlers addObject:handler];
    }
}

- (void)addHandlerWith:(CCDDamHttpInterruptBlock)httpInterruptBlock
{
    CCDDamHandler *handler = [[CCDDamHandler alloc] initWithHttpInterruptBlock:httpInterruptBlock];
    [self addHandler:handler];
}

- (void)removeHandler:(CCDDamHandler *)handler
{
    @synchronized (_handlers) {
        [_handlers removeObject:handler];
    }
}

- (void)removeAllHandlers
{
    @synchronized (_handlers) {
        [_handlers removeAllObjects];
    }
}

@end

@implementation CCDDamServer (HTTP)

- (BOOL)shouldHttpInterrupt:(NSURLRequest *)request
{
    if ([NSURLProtocol propertyForKey:kCCDDamURLProtocolHandledKey inRequest:request] || !self.enabled) {
        return NO;
    }
    
    if (![request.URL.scheme isEqualToString:@"http"]
        && ![request.URL.scheme isEqualToString:@"https"]) {
        return NO;
    }
    
    __block BOOL shouldInterrupt = YES;
    @synchronized (_handlers) {
        [_handlers enumerateObjectsUsingBlock:^(CCDDamHandler * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if (obj.interruptBlock && !obj.interruptBlock(request)) {
                shouldInterrupt = NO;
                *stop = YES;
            }
        }];
    }
    
    if (shouldInterrupt) {
        DDLogInfo(@"[interrupt]:%@:%@:%@", [request ccd_MD5], request.HTTPMethod, request.URL.absoluteURL);
    }
    return shouldInterrupt;
}

- (NSURLRequest *)canonicalRequest:(NSURLRequest *)request
{
    //替换为本地代理请求
    NSMutableURLRequest *mutableReqeust = [request ccd_requestWithCopyBody];
    [NSURLProtocol setProperty:@(YES) forKey:kCCDDamURLProtocolHandledKey inRequest:mutableReqeust];
    DDLogInfo(@"[canonical]:%@:%@:%@", [request ccd_MD5], request.HTTPMethod, request.URL.absoluteURL);
    return mutableReqeust;
}

@end
