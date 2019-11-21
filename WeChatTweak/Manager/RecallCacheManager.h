//
//  RecallCacheManager.h
//  WeChatTweak
//
//  Created by Sunny Young on 2019/8/29.
//  Copyright © 2019 Sunnyyoung. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MMKV/MMKV.h>

@class MessageData;

NS_ASSUME_NONNULL_BEGIN

@interface RecallCacheManager : NSObject

+ (instancetype)sharedInstance;

+ (void)insertRevokedMessage:(MessageData *)message;
+ (BOOL)containsRevokedMessage:(MessageData *)message;

@end

NS_ASSUME_NONNULL_END
