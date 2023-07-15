//
//  CCDBucketMonitor.m
//  Pods
//
//  Created by 十年之前 on 2023/7/15.
//

#import "CCDBucketMonitor.h"
#import "CCDBucket.h"

@implementation CCDBucketMonitorData

+ (instancetype)initWith:(NSString *)content
{
    CCDBucketMonitorData *data = [[CCDBucketMonitorData alloc] init];
    data.timestamp = [[NSDate date] timeIntervalSince1970];
    data.content = content;
    return data;
}

@end

@interface CCDBucketMonitor () <CCDBucketSubscriber>

@property (nonatomic, strong) NSMutableArray *dataList;

@property (nonatomic, strong) UITextView *textView;

@end

@implementation CCDBucketMonitor

+ (instancetype)sharedInstance
{
    static id sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (void)dealloc
{
    [[CCDBucket sharedInstance] removeObserver:self];
}

- (instancetype)init
{
    
    CGRect frame = [UIScreen mainScreen].bounds;
    frame.size.height = 200;
    self = [super initWithFrame:frame];
    if (self) {
        self.rootViewController = [[UIViewController alloc] init];
        self.windowLevel = UIWindowLevelAlert;
        self.backgroundColor = [UIColor colorWithWhite:0 alpha:0.3];
        self.userInteractionEnabled = NO;
        
        _textView = [[UITextView alloc] initWithFrame:self.bounds];
        _textView.font = [UIFont systemFontOfSize:16.0f];
        _textView.backgroundColor = [UIColor clearColor];
        _textView.scrollsToTop = NO;
        [self addSubview:_textView];
    }
    return self;
}

- (void)setup
{
    self.dataList = @[].mutableCopy;
    [[CCDBucket sharedInstance] addObserver:self];
}

- (void)cleanup
{
    [[CCDBucket sharedInstance] removeObserver:self];
    [self.dataList removeAllObjects];
    self.textView.text = @"";
}

#pragma mark - CCDBucketSubscriber

- (void)logWith:(NSString *)tag log:(NSString *)log
{
    NSString *content = [NSString stringWithFormat:@"[%@]%@\n", tag, log];
    CCDBucketMonitorData *data = [CCDBucketMonitorData initWith:content];
    [self addMonitorData:data];
}

- (void)trackWith:(NSString *)event params:(NSDictionary *)params
{
    NSString *detail = [self jsonStringWith:params options:NSJSONWritingPrettyPrinted];
    NSString *content = [NSString stringWithFormat:@"[%@]%@\n", event, detail];
    CCDBucketMonitorData *data = [CCDBucketMonitorData initWith:content];
    [self addMonitorData:data];
}

#pragma mark - display

- (NSString *)jsonStringWith:(NSDictionary *)params options:(NSJSONWritingOptions)opt
{
    NSError *error = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:params options:opt error:&error];
    if (jsonData == nil) {
#ifdef DEBUG
        NSLog(@"fail to get JSON from dictionary: %@, error: %@", params, error);
#endif
        return nil;
    }
    NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    return jsonString;
}

- (void)addMonitorData:(CCDBucketMonitorData *)data
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.dataList addObject:data];
        if (self.dataList.count > 20) {
            [self.dataList removeObjectAtIndex:0];
        }
        [self refreshMonitor];
    });
}

- (void)refreshMonitor
{
    NSMutableAttributedString *mutableAttrString = [[NSMutableAttributedString alloc] init];
    double currentTimestamp = [[NSDate date] timeIntervalSince1970];
    NSMutableDictionary *textAttrs = @{}.mutableCopy;
    textAttrs[NSFontAttributeName] = self.textView.font;
    
    for (CCDBucketMonitorData *data in self.dataList) {
        if (data.content.length == 0) {
            continue;
        }
        
        // yellow if new, white if more than 0.1 second ago
        NSMutableAttributedString *tempString = [[NSMutableAttributedString alloc] initWithString:data.content];
        if (currentTimestamp - data.timestamp > 0.1) {
            textAttrs[NSForegroundColorAttributeName] = [UIColor whiteColor];
        } else {
            textAttrs[NSForegroundColorAttributeName] = [UIColor yellowColor];
        }
        NSRange range = NSMakeRange(0, tempString.length);
        [tempString addAttributes:textAttrs range:range];
        
        [mutableAttrString appendAttributedString:tempString];
    }
    
    self.textView.attributedText = mutableAttrString;
        
    // scroll to bottom
    if(mutableAttrString.length > 0) {
        NSRange bottom = NSMakeRange(mutableAttrString.length - 1, 1);
        [self.textView scrollRangeToVisible:bottom];
    }
}

@end
