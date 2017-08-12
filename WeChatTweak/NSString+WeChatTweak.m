//
//  NSString+WeChatTweak.m
//  WeChatTweak
//
//  Created by Sunnyyoung on 2017/8/12.
//  Copyright © 2017年 Sunnyyoung. All rights reserved.
//

#import "NSString+WeChatTweak.h"

@implementation NSString (WeChatTweak)

- (NSString *)tweak_subStringFrom:(NSString *)beginString to:(NSString *)endString {
    NSRange begin = [self rangeOfString:beginString];
    NSRange end = [self rangeOfString:endString];
    NSRange range = NSMakeRange(begin.location + begin.length, end.location - begin.location - begin.length);
    return [self substringWithRange:range];
}

@end
