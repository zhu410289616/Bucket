//
//  CCDBucketMonitor.h
//  Pods
//
//  Created by 十年之前 on 2023/7/15.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface CCDBucketMonitorData : NSObject

/// data 生成的时间戳，单位为秒/s
@property (nonatomic, assign) double timestamp;
/// 展示数据
@property (nonatomic, strong) NSString *content;

+ (instancetype)initWith:(NSString *)content;

@end

/// 数据显示器
@interface CCDBucketMonitor : UIWindow

+ (instancetype)sharedInstance;

- (void)setup;
- (void)cleanup;

- (void)addMonitorData:(CCDBucketMonitorData *)data;

@end

NS_ASSUME_NONNULL_END
