//
//  WeChatTweak.m
//  WeChatTweak
//
//  Created by Sunnyyoung on 2017/8/11.
//  Copyright © 2017年 Sunnyyoung. All rights reserved.
//

#import "WeChatTweak.h"

@implementation WeChatTweak

+ (WeChatTweakNotificationType)notificationType {
    return [NSUserDefaults.standardUserDefaults integerForKey:@"WeChatTweakPreferenceRevokeNotificationTypeKey"];
}

+ (void)setNotificationType:(WeChatTweakNotificationType)notificationType {
    [NSUserDefaults.standardUserDefaults setInteger:notificationType forKey:@"WeChatTweakPreferenceRevokeNotificationTypeKey"];
}

+ (NSColor *)maskColor {
    NSData *data = [NSUserDefaults.standardUserDefaults objectForKey:@"WeChatTweakMaskColor"];
    return  data ? [NSUnarchiver unarchiveObjectWithData:data] : [NSColor.systemYellowColor colorWithAlphaComponent:0.3];
}

+ (void)setMaskColor:(NSColor *)maskColor {
    NSData *data = [NSArchiver archivedDataWithRootObject:maskColor];
    [NSUserDefaults.standardUserDefaults setObject:data forKey:@"WeChatTweakMaskColor"];
}

@end
