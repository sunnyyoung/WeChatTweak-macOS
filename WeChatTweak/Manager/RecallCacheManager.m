//
//  RecallCacheManager.m
//  WeChatTweak
//
//  Created by Sunny Young on 2019/8/29.
//  Copyright © 2019 Sunnyyoung. All rights reserved.
//

#import "RecallCacheManager.h"
#import "WeChatTweakHeaders.h"

@interface RecallCacheManager()

@property (nonatomic, strong) MMKV *kv;

@end

@implementation RecallCacheManager

- (instancetype)init {
    if (self = [super init]) {
        [MMKV setLogLevel:MMKVLogNone];
        _kv = [MMKV mmkvWithID:@"Recall.cache"];
    }
    return self;
}

+ (instancetype)sharedInstance {
    static RecallCacheManager *shared;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [[RecallCacheManager alloc] init];
    });
    return shared;
}

+ (void)insertRevokedMessage:(MessageData *)message {
    NSString *identifer = [NSString stringWithFormat:@"%ud-%lld-%ud", message.mesLocalID, message.mesSvrID, message.msgCreateTime];
    [RecallCacheManager.sharedInstance.kv setBool:YES forKey:identifer];
}

+ (BOOL)containsRevokedMessage:(MessageData *)message {
    NSString *identifer = [NSString stringWithFormat:@"%ud-%lld-%ud", message.mesLocalID, message.mesSvrID, message.msgCreateTime];
    return [RecallCacheManager.sharedInstance.kv containsKey:identifer];
}

@end
