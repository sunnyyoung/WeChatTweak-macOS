//
//  WeChatTweak.m
//  WeChatTweak
//
//  Created by Sunnyyoung on 2017/8/11.
//  Copyright © 2017年 Sunnyyoung. All rights reserved.
//

#import "WeChatTweak.h"
#import "WeChatTweakHeaders.h"
#import "fishhook.h"
#import "NSBundle+WeChatTweak.h"
#import "NSString+WeChatTweak.h"
#import "TweakPreferecesController.h"
#import "AlfredManager.h"
#import "WTConfigManager.h"

// Global Function
static NSString *(*original_NSHomeDirectory)(void);
static NSArray<NSString *> *(*original_NSSearchPathForDirectoriesInDomains)(NSSearchPathDirectory directory, NSSearchPathDomainMask domainMask, BOOL expandTilde);
NSString *tweak_NSHomeDirectory() {
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

@implementation NSObject (WeChatTweak)

#pragma mark - Constructor

static void __attribute__((constructor)) tweak(void) {
    // Global Function Hook
    rebind_symbols((struct rebinding[2]) {
        { "NSHomeDirectory", tweak_NSHomeDirectory, (void *)&original_NSHomeDirectory },
        { "NSSearchPathForDirectoriesInDomains", tweak_NSSearchPathForDirectoriesInDomains, (void *)&original_NSSearchPathForDirectoriesInDomains }
    }, 2);
    // Method Swizzling
    class_addMethod(objc_getClass("AppDelegate"), @selector(applicationDockMenu:), method_getImplementation(class_getInstanceMethod(objc_getClass("AppDelegate"), @selector(tweak_applicationDockMenu:))), "@:@");
    [objc_getClass("AppDelegate") jr_swizzleMethod:NSSelectorFromString(@"applicationDidFinishLaunching:") withMethod:@selector(tweak_applicationDidFinishLaunching:) error:nil];
    [objc_getClass("LogoutCGI") jr_swizzleMethod:NSSelectorFromString(@"sendLogoutCGIWithCompletion:") withMethod:@selector(tweak_sendLogoutCGIWithCompletion:) error:nil];
    [objc_getClass("AccountService") jr_swizzleMethod:NSSelectorFromString(@"onAuthOKOfUser:withSessionKey:withServerId:autoAuthKey:isAutoAuth:") withMethod:@selector(tweak_onAuthOKOfUser:withSessionKey:withServerId:autoAuthKey:isAutoAuth:) error:nil];
    [objc_getClass("AccountService") jr_swizzleMethod:NSSelectorFromString(@"ManualLogout") withMethod:@selector(tweak_ManualLogout) error:nil];
    [objc_getClass("MessageService") jr_swizzleMethod:NSSelectorFromString(@"onRevokeMsg:") withMethod:@selector(tweak_onRevokeMsg:) error:nil];
    [objc_getClass("CUtility") jr_swizzleClassMethod:NSSelectorFromString(@"HasWechatInstance") withClassMethod:@selector(tweak_HasWechatInstance) error:nil];
    [objc_getClass("MASPreferencesWindowController") jr_swizzleMethod:NSSelectorFromString(@"initWithViewControllers:") withMethod:@selector(tweak_initWithViewControllers:) error:nil];

    objc_property_attribute_t type = { "T", "@\"NSString\"" }; // NSString
    objc_property_attribute_t atom = { "N", "" }; // nonatomic
    objc_property_attribute_t ownership = { "&", "" }; // C = copy & = strong
    objc_property_attribute_t backingivar  = { "V", "_m_nsHeadImgUrl" }; // ivar name
    objc_property_attribute_t attrs[] = { type, atom, ownership, backingivar };
    class_addProperty(objc_getClass("WCContactData"), "wt_avatarPath", attrs, 4);
    class_addMethod(objc_getClass("WCContactData"), @selector(wt_avatarPath), method_getImplementation(class_getInstanceMethod(objc_getClass("WCContactData"), @selector(wt_avatarPath))), "@@:");
    class_addMethod(objc_getClass("WCContactData"), @selector(setWt_avatarPath:), method_getImplementation(class_getInstanceMethod(objc_getClass("WCContactData"), @selector(setWt_avatarPath:))), "v@:@");
    class_addMethod(objc_getClass("WCContactData"), @selector(modelPropertyWhitelist), method_getImplementation(class_getClassMethod(objc_getClass("WCContactData"), @selector(modelPropertyWhitelist))), "v@:");
}

#pragma mark - No Revoke Message

- (void)tweak_onRevokeMsg:(NSString *)message {
    // Decode message
    NSString *session = [message tweak_subStringFrom:@"<session>" to:@"</session>"];
    NSUInteger newMessageID = [message tweak_subStringFrom:@"<newmsgid>" to:@"</newmsgid>"].longLongValue;
    NSString *replaceMessage = [message tweak_subStringFrom:@"<replacemsg><![CDATA[" to:@"]]></replacemsg>"];

    // Prepare message data
    MessageData *localMessageData = [((MessageService *)self) GetMsgData:session svrId:newMessageID];
    MessageData *promptMessageData = ({
        MessageData *data = [[objc_getClass("MessageData") alloc] init];
        data.messageType = 10000;
        data.msgStatus = 4;
        data.toUsrName = localMessageData.toUsrName;
        data.fromUsrName = localMessageData.fromUsrName;
        data.mesLocalID = localMessageData.mesLocalID;
        data.msgCreateTime = localMessageData.msgCreateTime;
        if ([localMessageData isSendFromSelf]) {
            data.msgContent = replaceMessage;
        } else {
            data.msgContent = [NSString stringWithFormat:@"[已拦截]\n%@", replaceMessage];
        }
        data;
    });

    // Prepare notification information
    MMServiceCenter *serviceCenter = [objc_getClass("MMServiceCenter") defaultCenter];
    NSUserNotification *userNotification = [[NSUserNotification alloc] init];
    BOOL isChatStatusNotifyOpen = YES;
    if ([session rangeOfString:@"@chatroom"].location == NSNotFound) {
        ContactStorage *contactStorage = [serviceCenter getService:objc_getClass("ContactStorage")];
        WCContactData *contact = [contactStorage GetContact:session];
        isChatStatusNotifyOpen = [contact isChatStatusNotifyOpen];
        userNotification.informativeText = replaceMessage;
    } else {
        GroupStorage *groupStorage = [serviceCenter getService:objc_getClass("GroupStorage")];
        WCContactData *groupContact = [groupStorage GetGroupContact:session];
        isChatStatusNotifyOpen = [groupContact isChatStatusNotifyOpen];
        NSString *groupName = groupContact.m_nsNickName.length ? groupContact.m_nsNickName : @"群组";
        userNotification.informativeText = [NSString stringWithFormat:@"%@: %@", groupName, replaceMessage];
    }

    // Dispatch notification
    dispatch_async(dispatch_get_main_queue(), ^{
        // Delete message if it is revoke from myself
        if ([localMessageData isSendFromSelf]) {
            [((MessageService *)self) DelMsg:session msgList:@[localMessageData] isDelAll:NO isManual:YES];
            [((MessageService *)self) AddLocalMsg:session msgData:promptMessageData];
        } else {
            [((MessageService *)self) AddLocalMsg:session msgData:promptMessageData];
        }
        // Deliver notification
        if (![localMessageData isSendFromSelf]) {
            RevokeNotificationType notificationType = [[NSUserDefaults standardUserDefaults] integerForKey:WeChatTweakPreferenceRevokeNotificationTypeKey];
            if (notificationType == RevokeNotificationTypeReceiveAll || (notificationType == RevokeNotificationTypeFollow && isChatStatusNotifyOpen)) {
                [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:userNotification];
            }
        }
    });
}

#pragma mark - Mutiple Instance

+ (BOOL)tweak_HasWechatInstance {
    return NO;
}

- (NSMenu *)tweak_applicationDockMenu:(NSApplication *)sender {
    NSMenu *menu = [[NSMenu alloc] init];
    NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:@"登录新的微信账号" action:@selector(openNewWeChatInstace:) keyEquivalent:@""];
    [menu insertItem:menuItem atIndex:0];
    return menu;
}

- (void)openNewWeChatInstace:(id)sender {
    NSString *applicationPath = [[NSBundle mainBundle] bundlePath];
    NSTask *task = [[NSTask alloc] init];
    task.launchPath = @"/usr/bin/open";
    task.arguments = @[@"-n", applicationPath];
    [task launch];
}

#pragma mark - Auto Auth

- (void)tweak_applicationDidFinishLaunching:(NSNotification *)notification {
    [self tweak_applicationDidFinishLaunching:notification];
    NSString *bundleIdentifier = [[NSBundle mainBundle] bundleIdentifier];
    NSArray *instances = [NSRunningApplication runningApplicationsWithBundleIdentifier:bundleIdentifier];
    // Detect multiple instance conflict
    BOOL hasInstance = instances.count == 1;
    BOOL enabledAutoAuth = [[NSUserDefaults standardUserDefaults] boolForKey:WeChatTweakPreferenceAutoAuthKey];
    if (hasInstance && enabledAutoAuth) {
        AccountService *accountService = [[objc_getClass("MMServiceCenter") defaultCenter] getService:objc_getClass("AccountService")];
        if ([accountService canAutoAuth]) {
            [accountService AutoAuth];
        }
    }
}

- (void)tweak_onAuthOKOfUser:(id)arg1 withSessionKey:(id)arg2 withServerId:(id)arg3 autoAuthKey:(id)arg4 isAutoAuth:(BOOL)arg5 {
    [[AlfredManager sharedInstance] startListener];
    [self tweak_onAuthOKOfUser:arg1 withSessionKey:arg2 withServerId:arg3 autoAuthKey:arg4 isAutoAuth:arg5];
}

- (void)tweak_sendLogoutCGIWithCompletion:(id)completion {
    BOOL enabledAutoAuth = [[NSUserDefaults standardUserDefaults] boolForKey:WeChatTweakPreferenceAutoAuthKey];
    WeChat *wechat = [objc_getClass("WeChat") sharedInstance];
    if (enabledAutoAuth && wechat.isAppTerminating) {
        return;
    }
    [self tweak_sendLogoutCGIWithCompletion:completion];
}

- (void)tweak_ManualLogout {
    BOOL enabledAutoAuth = [[NSUserDefaults standardUserDefaults] boolForKey:WeChatTweakPreferenceAutoAuthKey];
    if (!enabledAutoAuth) {
        [self tweak_ManualLogout];
    }
}

#pragma mark - Preferences Window

- (id)tweak_initWithViewControllers:(NSArray *)arg1 {
    NSMutableArray *viewControllers = [NSMutableArray arrayWithArray:arg1];
    TweakPreferecesController *controller = [[TweakPreferecesController alloc] initWithNibName:nil bundle:[NSBundle tweakBundle]];
    [viewControllers addObject:controller];
    return [self tweak_initWithViewControllers:viewControllers];
}

#pragma mark - WCContact Data

- (NSString *)wt_avatarPath {
    MMAvatarService *avatarService = [[objc_getClass("MMServiceCenter") defaultCenter] getService:objc_getClass("MMAvatarService")];
    NSString *pathString = [NSString stringWithFormat:@"%@/%@", [avatarService avatarCachePath], [((WCContactData *)self).m_nsHeadImgUrl md5String]];
    return [NSFileManager.defaultManager fileExistsAtPath:pathString] ? pathString : @"";
}

- (void)setWt_avatarPath:(NSString *)avatarPath {
    // For readonly
    return;
}

+ (NSArray *)modelPropertyWhitelist {
    if (WTConfigManager.sharedInstance.compressedJSONEnabled) {
        return @[@"wt_avatarPath",
                 @"m_nsRemark",
                 @"m_nsNickName",
                 @"m_nsUsrName"];
    } else {
        return nil;
    }
}

@end