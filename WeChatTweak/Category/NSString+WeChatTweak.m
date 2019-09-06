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
    if (begin.location == NSNotFound) {
        return nil;
    }
    NSRange end = [self rangeOfString:endString];
    if (end.location == NSNotFound) {
        return nil;
    }
    NSRange range = NSMakeRange(begin.location + begin.length, end.location - begin.location - begin.length);
    if (range.location == NSNotFound) {
        return nil;
    }
    return [self substringWithRange:range];
}

@end
