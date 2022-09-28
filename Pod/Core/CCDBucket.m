//
//  CCDBucket.m
//  Pods
//
//  Created by 十年之前 on 2022/9/28.
//

#import "CCDBucket.h"

@interface CCDBucket ()

@property (nonatomic,   copy) NSString *workQueueLabel;
@property (nonatomic, strong) dispatch_queue_t workQueue;

@property (nonatomic, strong) NSHashTable *subscribers;

@end

@implementation CCDBucket

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
        //work queue
        _workQueueLabel = [NSString stringWithFormat:@"%p.com.zrh.bucket.queue", self];
        _workQueue = dispatch_queue_create([_workQueueLabel UTF8String], DISPATCH_QUEUE_SERIAL);
        //data subscribers
        _subscribers = [NSHashTable hashTableWithOptions:NSPointerFunctionsWeakMemory];
    }
    return self;
}

#pragma mark - data subscriber

- (void)addObserver:(id<CCDBucketSubscriber>)observer
{
    [self runOnWorkQueue:^{
        !observer ?: [self.subscribers addObject:observer];
    }];
}

- (void)removeObserver:(id<CCDBucketSubscriber>)observer
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

@implementation CCDBucket (Log)

- (void)logWith:(NSString *)tag log:(NSString *)log
{
    [self runOnWorkQueue:^{
        NSHashTable *subs = [self.subscribers mutableCopy];
        for (id<CCDBucketSubscriber> sub in subs) {
            [sub logWith:tag log:log];
        }
    }];
}

@end

@implementation CCDBucket (Track)

- (void)trackWith:(NSString *)event params:(NSDictionary *)params
{
    [self runOnWorkQueue:^{
        NSHashTable *subs = [self.subscribers mutableCopy];
        for (id<CCDBucketSubscriber> sub in subs) {
            [sub trackWith:event params:params];
        }
    }];
}

@end
