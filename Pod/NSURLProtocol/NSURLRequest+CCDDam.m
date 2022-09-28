//
//  NSURLRequest+CCDDam.m
//  Pods
//
//  Created by 十年之前 on 2022/9/23.
//

#import "NSURLRequest+CCDDam.h"
#import <CommonCrypto/CommonDigest.h>

@implementation NSURLRequest (CCDDam)

- (NSMutableURLRequest *)ccd_requestWithCopyBody
{
    NSMutableURLRequest *request = [self mutableCopy];
    //copy body
    if ([self.HTTPMethod isEqualToString:@"POST"]) {
        if (!self.HTTPBody) {
            NSInteger bufferLen = 1024;
            uint8_t buffer[bufferLen];
            NSInputStream *stream = self.HTTPBodyStream;
            NSMutableData *data = [NSMutableData data];
            [stream open];
            BOOL endOfStreamReached = NO;
            while (!endOfStreamReached) {
                NSInteger bytesRead = [stream read:buffer maxLength:bufferLen];
                if (bytesRead == 0) {
                    endOfStreamReached = YES;
                } else if (bytesRead == -1) {
                    endOfStreamReached = YES;
                } else if (stream.streamError == nil) {
                    [data appendBytes:buffer length:bytesRead];
                }
            }//while
            request.HTTPBody = data;
            [stream close];
        }
    }
    return request;
}

- (NSString *)ccd_MD5
{
    NSString *url = self.URL.absoluteString;
    
    NSMutableString *md5String = nil;
    if (url.length) {
        const char *value = [url UTF8String];
        unsigned char outputBuffer[CC_MD5_DIGEST_LENGTH];
        CC_MD5(value, (CC_LONG)strlen(value), outputBuffer);
        
        md5String = [[NSMutableString alloc] initWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
        for (NSInteger count = 0; count < CC_MD5_DIGEST_LENGTH; count++) {
            [md5String appendFormat:@"%02x", outputBuffer[count]];
        }
    }
    return md5String;
}

@end
