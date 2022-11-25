//
//  NSURLProtocol+WebKitSupport.h
//  NSURLProtocol+WebKitSupport
//
//  Created by yeatse on 2016/10/11.
//  Copyright © 2016年 Yeatse. All rights reserved.
//
// from https://github.com/Yeatse/NSURLProtocol-WebKitSupport

#import <Foundation/Foundation.h>

@interface NSURLProtocol (CCDWebKit)

+ (void)wk_registerScheme:(NSString*)scheme;

+ (void)wk_unregisterScheme:(NSString*)scheme;

@end
