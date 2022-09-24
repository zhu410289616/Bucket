//
//  NSURLRequest+CCDDam.h
//  Pods
//
//  Created by 十年之前 on 2022/9/23.
//

#import <Foundation/Foundation.h>

@interface NSURLRequest (CCDDam)

/// 在 task.originalRequest.HTTPBody 中实际获取的值为空，需要手动 copy 一份；
- (NSMutableURLRequest *)ccd_requestWithCopyBody;

/// 通过 MD5(URL) 标记同一个请求；
- (NSString *)ccd_MD5;

@end
