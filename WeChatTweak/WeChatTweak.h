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

typedef NS_ENUM(NSUInteger, WTRevokedMessageStyle) {
    WTRevokedMessageStyleClassic = 0,
    WTRevokedMessageStyleMask
};

@interface WeChatTweak : NSObject

@property (nonatomic, assign, class) BOOL compressedJSONEnabled;
@property (nonatomic, assign, class) WTRevokedMessageStyle revokedMessageStyle;

@end
