//
//  TweakPreferencesController.h
//  WeChatTweak
//
//  Created by Sunnyyoung on 2017/8/12.
//  Copyright © 2017年 Sunnyyoung. All rights reserved.
//

#import "WeChatTweakHeaders.h"

typedef NS_ENUM(NSUInteger, RevokeNotificationType) {
    RevokeNotificationTypeFollow = 0,
    RevokeNotificationTypeReceiveAll,
    RevokeNotificationTypeDisable,
};

static NSString * const WeChatTweakPreferenceAutoAuthKey = @"WeChatTweakPreferenceAutoAuthKey";
static NSString * const WeChatTweakPreferenceRevokeNotificationTypeKey = @"WeChatTweakPreferenceRevokeNotificationTypeKey";

@interface TweakPreferencesController : NSViewController

@end
