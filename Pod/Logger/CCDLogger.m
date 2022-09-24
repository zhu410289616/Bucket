//
//  CCDLogger.m
//  Pods
//
//  Created by 十年之前 on 2022/9/21.
//

#import "CCDLogger.h"

@interface CCDLogger ()

@property (nonatomic,   copy) NSString *workQueueLabel;
@property (nonatomic, strong) dispatch_queue_t workQueue;

@property (nonatomic, strong) NSHashTable *subscribers;

@end

@implementation CCDLogger

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
        //queue
        _workQueueLabel = [NSString stringWithFormat:@"%p.com.zrh.log.queue", self];
        _workQueue = dispatch_queue_create([_workQueueLabel UTF8String], DISPATCH_QUEUE_SERIAL);
        //
        _subscribers = [NSHashTable hashTableWithOptions:NSPointerFunctionsWeakMemory];
    }
    return self;
}

#pragma mark - log

- (void)log:(NSString *)format, ...
{
    [self runOnWorkQueue:^{
        NSString *log = [NSString stringWithFormat:@"%@", format];
        NSHashTable *subs = [self.subscribers mutableCopy];
        for (id<CCDLogSubscriber> sub in subs) {
            [sub log:log];
        }
    }];
}

#pragma mark - CCDLogSubscriber

- (void)addObserver:(id<CCDLogSubscriber>)observer
{
    [self runOnWorkQueue:^{
        !observer ?: [self.subscribers addObject:observer];
    }];
}

- (void)removeObserver:(id<CCDLogSubscriber>)observer
{
    [self runOnWorkQueue:^{
        !observer ?: [self.subscribers removeObject:observer];
    }];
}

#pragma mark - work queue

- (void)runOnWorkQueue:(dispatch_block_t)block
{
    if (dispatch_get_specific([self.workQueueLabel UTF8String])) {
        block();
    } else {
        dispatch_async(self.workQueue, block);
    }
}

@end

#pragma mark - Custom Logger

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

- (void)logMessage:(DDLogMessage *)logMessage
{
    NSString *msg = logMessage->_message;
    if (self->_logFormatter) {
        msg = [self->_logFormatter formatLogMessage:logMessage];
    }
    [[CCDLogger sharedInstance] log:msg];
}

@end
