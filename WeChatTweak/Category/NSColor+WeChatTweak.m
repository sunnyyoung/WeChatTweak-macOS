//
//  NSColor+WeChatTweak.m
//  WeChatTweak
//
//  Created by Jeason Lee on 2019/11/1.
//  Copyright © 2019 Sunnyyoung. All rights reserved.
//

#import "NSColor+WeChatTweak.h"

@implementation NSColor (WeChatTweak)

+ (NSColor *)tweak_revokeBackgroundColor {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSData *colorData = [userDefaults objectForKey:WeChatTweakPreferenceRevokeBackgroundColorKey];
    NSColor *color = [NSKeyedUnarchiver unarchiveObjectWithData:colorData];
    if(![color isKindOfClass:[NSColor class]]){
        color = [NSColor colorWithRed:250/255.0 green:250/255.0 blue:205/255.0 alpha:1];
        NSData *colorData = [NSKeyedArchiver archivedDataWithRootObject:color];
        [userDefaults setObject:colorData forKey:WeChatTweakPreferenceRevokeBackgroundColorKey];
        [userDefaults synchronize];
    }
    return color;
}

@end
