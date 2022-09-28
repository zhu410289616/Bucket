//
//  CCDTracker.m
//  Pods
//
//  Created by 十年之前 on 2022/9/28.
//

#import "CCDTracker.h"
#import "CCDBucket.h"

void CCDTrack(NSString *event, NSDictionary *params)
{
    [[CCDBucket sharedInstance] trackWith:event params:params];
}

@implementation CCDTracker

@end
