//
//  NSBundle+WeChatTweak.m
//  WeChatTweak
//
//  Created by Sunnyyoung on 2017/8/12.
//  Copyright © 2017年 Sunnyyoung. All rights reserved.
//

#import "NSBundle+WeChatTweak.h"

@implementation NSBundle (WeChatTweak)

+ (instancetype)tweakBundle {
    return [NSBundle bundleWithIdentifier:@"net.sunnyyoung.WeChatTweak"];
}

- (NSString *)localizedStringForKey:(NSString *)key {
    return [self localizedStringForKey:key value:nil table:nil];
}

@end
