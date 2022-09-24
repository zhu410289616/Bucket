//
//  CCDMarsLogger.m
//  Cicada
//
//  Created by zhuruhong on 2020/4/2.
//

#import "CCDMarsLogger.h"

#import <sys/xattr.h>
#import <mars/xlog/xlogger.h>
#import <mars/xlog/appender.h>

@implementation CCDMarsLogFormatter

- (NSString *)formatMessage:(NSString *)message
{
    return message;
}

@end

#pragma mark -

@implementation CCDMarsLoggerConfig

@end

#pragma mark -

@interface CCDMarsLogger ()

@property (nonatomic, strong) id<CCDMarsLogFormatter> logFormatter;
@property (nonatomic, strong) NSString *fileDir;
@property (nonatomic, strong) NSString *filePrefix;

@end

@implementation CCDMarsLogger

- (instancetype)initWithConfig:(CCDMarsLoggerConfig * (^)(void))builder
{
    self = [super init];
    if (self) {
        CCDMarsLoggerConfig *config = builder ? builder() : nil;
        _logFormatter = config.logFormatter;
        _fileDir = config.fileDir;
        _filePrefix = config.filePrefix;
    }
    return self;
}

- (id<CCDMarsLogFormatter>)logFormatter
{
    if (nil == _logFormatter) {
        _logFormatter = [[CCDMarsLogFormatter alloc] init];
    }
    return _logFormatter;
}

- (NSString *)fileDir
{
    if (nil == _fileDir) {
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentPath = paths.firstObject;
        _fileDir = [documentPath stringByAppendingPathComponent:@"MarsLog"];
#ifdef DEBUG
        NSLog(@"[CCDMarsLogger] dir: %@", _fileDir);
#endif
    }
    return _fileDir;
}

- (NSString *)filePrefix
{
    if (nil == _filePrefix) {
        _filePrefix = @"Cicada";
    }
    return _filePrefix;
}

- (void)open
{
    const char * dir = [self.fileDir UTF8String];
    
    // set do not backup for logpath
    const char* attrName = "com.apple.MobileBackup";
    u_int8_t attrValue = 1;
    setxattr(dir, attrName, &attrValue, sizeof(attrValue), 0, 0);
    
    // init xlog
#if DEBUG
    xlogger_SetLevel(kLevelDebug);
    appender_set_console_log(false);
#else
    xlogger_SetLevel(kLevelInfo);
    appender_set_console_log(false);
#endif
    
    /*
     * 设置日志目录、日志文件前缀
     * 特别强调一点pubkey，设置后才会对日志进行加密，若Debug模式下不希望加密，可以设置空""
     * pubkey在decode_mars_crypt_log_file.py脚本中
     */
    const char * namePrefix = [self.filePrefix UTF8String];
    const char * pubKey = NULL;
    appender_open(kAppednerAsync, dir, namePrefix, pubKey);
}

- (void)close
{
    appender_close();
}

- (void)log:(NSString *)format
{
    NSString *message = format;
    if ([self.logFormatter respondsToSelector:@selector(formatMessage:)]) {
        message = [self.logFormatter formatMessage:message];
    }
    xinfo2("%s", [message UTF8String]);

#ifdef DEBUG
    NSLog(@"[%@]: %@", self.class, message);
#endif
}

@end
