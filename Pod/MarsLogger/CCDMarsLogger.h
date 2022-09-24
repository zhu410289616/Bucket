//
//  CCDMarsLogger.h
//  Cicada
//
//  Created by zhuruhong on 2020/4/2.
//

#import <Foundation/Foundation.h>

//腾讯 mars 日志：https://github.com/Tencent/mars

//NS_ASSUME_NONNULL_BEGIN

@protocol CCDMarsLogFormatter <NSObject>

- (NSString *)formatMessage:(NSString *)message;

@end

@interface CCDMarsLogFormatter : NSObject <CCDMarsLogFormatter>

@end

#pragma mark -

@interface CCDMarsLoggerConfig : NSObject

@property (nonatomic, strong) id<CCDMarsLogFormatter> logFormatter;
@property (nonatomic, strong) NSString *fileDir;
@property (nonatomic, strong) NSString *filePrefix;

@end

#pragma mark -

@interface CCDMarsLogger : NSObject

- (instancetype)initWithConfig:(CCDMarsLoggerConfig * (^)(void))builder;

- (void)open;
- (void)close;

- (void)log:(NSString *)format;

@end

//NS_ASSUME_NONNULL_END
