//
//  NSBundle+WeChatTweak.h
//  WeChatTweak
//
//  Created by Sunnyyoung on 2017/8/12.
//  Copyright © 2017年 Sunnyyoung. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NSBundle (WeChatTweak)

+ (instancetype)tweakBundle;
- (NSString *)localizedStringForKey:(NSString *)key;

@end
