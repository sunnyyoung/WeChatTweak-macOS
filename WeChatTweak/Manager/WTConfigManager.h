//
//  WTConfigManager.h
//  WeChatTweak
//
//  Created by Sunny Young on 21/03/2018.
//  Copyright © 2018 Sunnyyoung. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <objc/runtime.h>
#import <objc/message.h>

typedef NS_ENUM(NSUInteger, WTRevokedMessageStyle) {
    WTRevokedMessageStylePlain = 0,
    WTRevokedMessageStyleMask
};

@interface WTConfigManager : NSObject

@property (nonatomic, assign) BOOL compressedJSONEnabled;
@property (nonatomic, assign) WTRevokedMessageStyle revokedMessageStyle;

+ (instancetype)sharedInstance;

@end
