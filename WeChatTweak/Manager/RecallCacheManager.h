//
//  RecallCacheManager.h
//  WeChatTweak
//
//  Created by Sunny Young on 2019/8/29.
//  Copyright © 2019 Sunnyyoung. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MMKV/MMKV.h>

NS_ASSUME_NONNULL_BEGIN

@interface RecallCacheManager : NSObject

+ (instancetype)sharedInstance;

+ (void)insertRevokedMessageID:(long long)messageID;
+ (BOOL)containsRevokedMessageID:(long long)messageID;

@end

NS_ASSUME_NONNULL_END
