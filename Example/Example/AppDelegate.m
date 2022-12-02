//
//  AppDelegate.m
//  Example
//
//  Created by zhuruhong on 2022/11/21.
//

#import "AppDelegate.h"
#import <CCDBucket/CCDLogger.h>
#import <CCDBucket/CCDDamServer.h>

@interface AppDelegate ()

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application willFinishLaunchingWithOptions:(NSDictionary<UIApplicationLaunchOptionsKey,id> *)launchOptions {
    //log
    CCDTraceLogger *traceLogger = [[CCDTraceLogger alloc] init];
    traceLogger.logFormatter = [[CCDTraceLogFormatter alloc] init];
    [DDLog addLogger:traceLogger];
    [DDLog addLogger:[DDTTYLogger sharedInstance]];
    if (@available(iOS 10.0, *)) {
        [DDLog addLogger:[DDOSLogger sharedInstance]];
    } else {
        // Fallback on earlier versions
        [DDLog addLogger:[DDASLLogger sharedInstance]];
    }
    DDLogInfo(@"[willFinishLaunchingWithOptions]: DDLog init");
    return YES;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    [self startDamServerForWebBrower];
    return YES;
}

#pragma mark - dam server

- (void)startDamServerForWebBrower
{
    //dam server
    [[CCDDamServer sharedInstance] addHandlerWith:^BOOL(NSURLRequest *request) {
        if ([request.URL.absoluteString hasSuffix:@"test"]) {
            return NO;
        }
        return YES;
    }];
    [[CCDDamServer sharedInstance] setEnabled:YES];
    [[CCDDamServer sharedInstance] start];
    DDLogInfo(@"[didFinishLaunchingWithOptions]: dam server init");
}

#pragma mark - UISceneSession lifecycle


- (UISceneConfiguration *)application:(UIApplication *)application configurationForConnectingSceneSession:(UISceneSession *)connectingSceneSession options:(UISceneConnectionOptions *)options {
    // Called when a new scene session is being created.
    // Use this method to select a configuration to create the new scene with.
    return [[UISceneConfiguration alloc] initWithName:@"Default Configuration" sessionRole:connectingSceneSession.role];
}


- (void)application:(UIApplication *)application didDiscardSceneSessions:(NSSet<UISceneSession *> *)sceneSessions {
    // Called when the user discards a scene session.
    // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
    // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
}


@end
