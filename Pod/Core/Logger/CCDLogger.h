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

FOUNDATION_EXPORT void CCDLog(NSString *tag, NSString *log);

@interface CCDLogger : NSObject

@end

#pragma mark - Trace Logger

@interface CCDTraceLogFormatter : NSObject <DDLogFormatter>

@end

/// 通过日志收集数据，达到埋点/监控的目的
@interface CCDTraceLogger : DDAbstractLogger

@end
