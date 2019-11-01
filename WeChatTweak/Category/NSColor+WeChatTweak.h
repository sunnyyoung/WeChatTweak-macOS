//
//  NSColor+WeChatTweak.h
//  WeChatTweak
//
//  Created by Jeason Lee on 2019/11/1.
//  Copyright © 2019 Sunnyyoung. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

static NSString * const WeChatTweakPreferenceRevokeBackgroundColorKey = @"WeChatTweakPreferenceRevokeBackgroundColorKey";

@interface NSColor (WeChatTweak)

+ (NSColor *)tweak_revokeBackgroundColor;

@end

NS_ASSUME_NONNULL_END
