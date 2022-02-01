//
//  Directory.m
//  WeChatTweak
//
//  Created by Sunny Young on 2022/2/1.
//  Copyright © 2022 Sunnyyoung. All rights reserved.
//

#import "WeChatTweak.h"
#import "fishhook.h"

static NSString *(*original_NSHomeDirectory)(void);
static NSArray<NSString *> *(*original_NSSearchPathForDirectoriesInDomains)(NSSearchPathDirectory directory, NSSearchPathDomainMask domainMask, BOOL expandTilde);
NSString *tweak_NSHomeDirectory(void) {
    return [original_NSHomeDirectory() stringByAppendingPathComponent:@"/Library/Containers/com.tencent.xinWeChat/Data/"];
}
NSArray<NSString *> *tweak_NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory directory, NSSearchPathDomainMask domainMask, BOOL expandTilde) {
    if (domainMask == NSUserDomainMask) {
        NSMutableArray<NSString *> *directories = [original_NSSearchPathForDirectoriesInDomains(directory, domainMask, expandTilde) mutableCopy];
        [directories enumerateObjectsUsingBlock:^(NSString * _Nonnull object, NSUInteger index, BOOL * _Nonnull stop) {
            switch (directory) {
                case NSDocumentDirectory: directories[index] = [tweak_NSHomeDirectory() stringByAppendingPathComponent:@"Documents"]; break;
                case NSLibraryDirectory: directories[index] = [tweak_NSHomeDirectory() stringByAppendingPathComponent:@"Library"]; break;
                case NSApplicationSupportDirectory: directories[index] = [tweak_NSHomeDirectory() stringByAppendingPathComponent:@"Library/Application Support"]; break;
                case NSCachesDirectory: directories[index] = [tweak_NSHomeDirectory() stringByAppendingPathComponent:@"Library/Caches"]; break;
                default: break;
            }
        }];
        return directories;
    } else {
        return original_NSSearchPathForDirectoriesInDomains(directory, domainMask, expandTilde);
    }
}

static void __attribute__((constructor)) tweak(void) {
    // Global Function Hook
    rebind_symbols((struct rebinding[2]) {
        { "NSHomeDirectory", tweak_NSHomeDirectory, (void *)&original_NSHomeDirectory },
        { "NSSearchPathForDirectoriesInDomains", tweak_NSSearchPathForDirectoriesInDomains, (void *)&original_NSSearchPathForDirectoriesInDomains }
    }, 2);
}
