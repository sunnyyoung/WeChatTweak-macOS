//
//  WeChatTweak.m
//  WeChatTweak
//
//  Created by Sunnyyoung on 2017/8/11.
//  Copyright © 2017年 Sunnyyoung. All rights reserved.
//

#import "WeChatTweak.h"

static NSString * const WeChatTweakRevokedMessageStyleKey = @"WeChatTweakRevokedMessageStyleKey";

@implementation WeChatTweak

+ (WTRevokedMessageStyle)revokedMessageStyle {
    return [NSUserDefaults.standardUserDefaults integerForKey:WeChatTweakRevokedMessageStyleKey];
}

+ (void)setRevokedMessageStyle:(WTRevokedMessageStyle)revokedMessageStyle {
    [NSUserDefaults.standardUserDefaults setInteger:revokedMessageStyle forKey:WeChatTweakRevokedMessageStyleKey];
    [NSUserDefaults.standardUserDefaults synchronize];
}

@end
