//
//  CCDLogger.h
//  Pods
//
//  Created by 十年之前 on 2022/9/21.
//

#import <Foundation/Foundation.h>
#import <CocoaLumberjack/CocoaLumberjack.h>

// Log levels: off, error, warn, info, verbose
static const DDLogLevel ddLogLevel = DDLogLevelVerbose;

@protocol CCDLogSubscriber <NSObject>

- (void)log:(NSString *)log;

@end

@protocol CCDLogger <NSObject>

- (void)addObserver:(id<CCDLogSubscriber>)observer;
- (void)removeObserver:(id<CCDLogSubscriber>)observer;

- (void)log:(NSString *)format, ...;

@end

@interface CCDLogger : NSObject <CCDLogger>

+ (instancetype)sharedInstance;

@end

#pragma mark - Custom Logger

@interface CCDTraceLogFormatter : NSObject <DDLogFormatter>

@end

/// 通过日志收集数据，达到埋点/监控的目的
@interface CCDTraceLogger : DDAbstractLogger

@end
