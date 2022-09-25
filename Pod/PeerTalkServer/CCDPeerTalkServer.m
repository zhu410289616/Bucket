//
//  CCDPeerTalkServer.m
//  Pods
//
//  Created by 十年之前 on 2022/9/25.
//

#import "CCDPeerTalkServer.h"
#import "CCDLogger.h"
#import <KKConnectorServer/KKConnectorServer.h>

@interface CCDPeerTalkServer () <KKConnectorServerDelegate, CCDLogSubscriber>

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

- (instancetype)init
{
    self = [super init];
    if (self) {
        [[KKConnectorServer sharedInstance] registerAppID:100 protocolVersion:@"0.0.1" delegate:self];
        [[CCDLogger sharedInstance] addObserver:self];
    }
    return self;
}

#pragma mark - KKConnectorServerDelegate

- (void)connectorServerDidReceiveRequestHeader:(NSString *)header body:(nullable id)body handler:(nullable KKConnectorServerRequestHandler *)handler
{
    DDLogInfo(@"header: %@", header);
}

#pragma mark - CCDLogSubscriber

- (void)log:(NSString *)log
{
    NSData *body = [log dataUsingEncoding:NSUTF8StringEncoding];
    [[KKConnectorServer sharedInstance] sendFrameOfType:104 tag:1 withPayload:body];
}

@end
