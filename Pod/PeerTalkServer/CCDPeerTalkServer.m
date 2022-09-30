//
//  CCDPeerTalkServer.m
//  Pods
//
//  Created by 十年之前 on 2022/9/25.
//

#import "CCDPeerTalkServer.h"
#import "CCDBucket.h"
#import <KKConnectorServer/KKConnectorServer.h>

@interface CCDPeerTalkServer ()
<
KKConnectorServerDelegate,
CCDBucketSubscriber
>

@end

@implementation CCDPeerTalkServer

+ (instancetype)sharedInstance
{
    static id sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (void)dealloc
{
    [[CCDBucket sharedInstance] removeObserver:self];
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        [[KKConnectorServer sharedInstance] registerAppID:100 protocolVersion:@"0.0.1" delegate:self];
        [[CCDBucket sharedInstance] addObserver:self];
    }
    return self;
}

#pragma mark - KKConnectorServerDelegate

- (void)connectorServerDidReceiveRequestHeader:(NSString *)header body:(nullable id)body handler:(nullable KKConnectorServerRequestHandler *)handler
{
    DDLogInfo(@"header: %@", header);
}

#pragma mark - CCDBucketSubscriber

- (void)logWith:(NSString *)tag log:(NSString *)log
{
    NSString *tempStr = [NSString stringWithFormat:@"[%@] %@", tag, log];
    NSData *body = [tempStr dataUsingEncoding:NSUTF8StringEncoding];
    [[KKConnectorServer sharedInstance] sendFrameOfType:104 tag:1 withPayload:body];
}

- (void)trackWith:(NSString *)event params:(NSDictionary *)params
{
    NSString *tempStr = [NSString stringWithFormat:@"[%@] %@", event, params];
    NSData *body = [tempStr dataUsingEncoding:NSUTF8StringEncoding];
    [[KKConnectorServer sharedInstance] sendFrameOfType:104 tag:1 withPayload:body];
}

@end
