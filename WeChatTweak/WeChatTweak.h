//
//  WeChatTweak.h
//  WeChatTweak
//
//  Created by Sunnyyoung on 2017/8/11.
//  Copyright © 2017年 Sunnyyoung. All rights reserved.
//

#import "WeChatTweakHeaders.h"

FOUNDATION_EXPORT double WeChatTweakVersionNumber;
FOUNDATION_EXPORT const unsigned char WeChatTweakVersionString[];

typedef NS_ENUM(NSUInteger, WeChatTweakNotificationType) {
    WeChatTweakNotificationTypeInherited = 0,
    WeChatTweakNotificationTypeReceiveAll,
    WeChatTweakNotificationTypeDisable
};

@interface WeChatTweak : NSObject

@property (class, assign) WeChatTweakNotificationType notificationType;
@property (class, nonnull) NSColor *maskColor;

@end
