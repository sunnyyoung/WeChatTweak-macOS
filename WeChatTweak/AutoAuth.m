//
//  AutoAuth.m
//  WeChatTweak
//
//  Created by Sunny Young on 2021/5/8.
//  Copyright © 2021 Sunnyyoung. All rights reserved.
//

#import "AutoAuth.h"
#import "WeChatTweakHeaders.h"
#import "WTConfigManager.h"

@implementation NSObject(AutoAuth)

static void __attribute__((constructor)) tweak(void) {
    [objc_getClass("MMLoginOneClickViewController") jr_swizzleMethod:NSSelectorFromString(@"onLoginButtonClicked:") withMethod:@selector(tweak_onLoginButtonClicked:) error:nil];
    [objc_getClass("MMMainViewController") jr_swizzleMethod:NSSelectorFromString(@"viewDidLoad") withMethod:@selector(tweak_viewDidLoad) error:nil];
    [objc_getClass("LogoutCGI") jr_swizzleMethod:NSSelectorFromString(@"FFVCRecvDataAddDataToMsgChatMgrRecvZZ:") withMethod:@selector(tweak_FFVCRecvDataAddDataToMsgChatMgrRecvZZ:) error:nil];
    [objc_getClass("AccountService") jr_swizzleMethod:NSSelectorFromString(@"FFAddSvrMsgImgVCZZ") withMethod:@selector(tweak_FFAddSvrMsgImgVCZZ) error:nil];
}

- (void)tweak_onLoginButtonClicked:(id)sender {
    AccountService *accountService = [[objc_getClass("MMServiceCenter") defaultCenter] getService:objc_getClass("AccountService")];
    BOOL enabledAutoAuth = [NSUserDefaults.standardUserDefaults boolForKey:WeChatTweakPreferenceAutoAuthKey];
    BOOL canAutoAuth = accountService.canAutoAuth;
    if (enabledAutoAuth && canAutoAuth) {
        [accountService AutoAuth];
    } else {
        [self tweak_onLoginButtonClicked:sender];
    }
}

- (void)tweak_viewDidLoad {
    [self tweak_viewDidLoad];
    if ([NSUserDefaults.standardUserDefaults boolForKey:WeChatTweakPreferenceAutoAuthKey]) {
        MMSessionMgr *mgr = [[objc_getClass("MMServiceCenter") defaultCenter] getService:objc_getClass("MMSessionMgr")];
        [mgr loadSessionData];
        [mgr loadBrandSessionData];
    }
}

- (void)tweak_FFVCRecvDataAddDataToMsgChatMgrRecvZZ:(id)arg {
    if (![NSUserDefaults.standardUserDefaults boolForKey:WeChatTweakPreferenceAutoAuthKey]) {
        [self tweak_FFVCRecvDataAddDataToMsgChatMgrRecvZZ:arg];
    }
}

- (void)tweak_FFAddSvrMsgImgVCZZ {
    if ([NSUserDefaults.standardUserDefaults boolForKey:WeChatTweakPreferenceAutoAuthKey]) {
        return;
    } else {
        [self tweak_FFAddSvrMsgImgVCZZ];
    }
}

@end
