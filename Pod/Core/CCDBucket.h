//
//  CCDBucket.h
//  Pods
//
//  Created by 十年之前 on 2022/9/28.
//

#import <Foundation/Foundation.h>
#import "CCDLogger.h"
#import "CCDTracker.h"

@protocol CCDBucketSubscriber <NSObject>

- (void)logWith:(NSString *)tag log:(NSString *)log;
- (void)trackWith:(NSString *)event params:(NSDictionary *)params;

@end

/// 通过 Bucket 收集日志/埋点/监控等数据，用于问题定位，数据分析等目的；
@interface CCDBucket : NSObject

+ (instancetype)sharedInstance;

#pragma mark - data subscriber

- (void)addObserver:(id<CCDBucketSubscriber>)observer;
- (void)removeObserver:(id<CCDBucketSubscriber>)observer;

@end

@interface CCDBucket (Log)

- (void)logWith:(NSString *)tag log:(NSString *)log;

@end

@interface CCDBucket (Track)

- (void)trackWith:(NSString *)event params:(NSDictionary *)params;

@end
