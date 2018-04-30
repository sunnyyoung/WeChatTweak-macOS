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

@interface WTConfigManager : NSObject

@property (nonatomic, assign) BOOL compressedJSONEnabled;

+ (instancetype)sharedInstance;

@end
