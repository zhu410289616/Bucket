//
//  CCDLogger.m
//  Pods
//
//  Created by 十年之前 on 2022/9/21.
//

#import "CCDLogger.h"
#import "CCDBucket.h"

void CCDLog(NSString *tag, NSString *log)
{
    DDLogVerbose(@"[%@]%@", tag, log);
}

@interface CCDLogger ()

@end

@implementation CCDLogger

@end

#pragma mark - Trace Logger

@interface CCDTraceLogFormatter ()
{
    NSDateFormatter *_dateFormatter;
}

@end

@implementation CCDTraceLogFormatter

- (instancetype)init
{
    self = [super init];
    if (self) {
        _dateFormatter = [[NSDateFormatter alloc] init];
        [_dateFormatter setFormatterBehavior:NSDateFormatterBehavior10_4]; // 10.4+ style
        [_dateFormatter setLocale:[NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"]];
        [_dateFormatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
        [_dateFormatter setDateFormat:@"[yyyy/MM/dd HH:mm:ss:SSS]"];
    }
    return self;
}

- (NSString *)formatLogMessage:(DDLogMessage *)logMessage
{
    NSString *dateAndTime = [_dateFormatter stringFromDate:logMessage->_timestamp];
    return [NSString stringWithFormat:@"%@ %@", dateAndTime, logMessage->_message];
}

@end

@implementation CCDTraceLogger

#pragma mark - DDLogger

- (void)logMessage:(DDLogMessage *)logMessage
{
    NSString *msg = logMessage->_message;
    if (self->_logFormatter) {
        msg = [self->_logFormatter formatLogMessage:logMessage];
    }
    [[CCDBucket sharedInstance] logWith:@"V" log:msg];
}

@end
