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

// Global Function
static NSArray<NSString *> *(*original_NSSearchPathForDirectoriesInDomains)(NSSearchPathDirectory directory, NSSearchPathDomainMask domainMask, BOOL expandTilde);
NSArray<NSString *> *tweak_NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory directory, NSSearchPathDomainMask domainMask, BOOL expandTilde) {
    if (domainMask == NSUserDomainMask) {
        NSMutableArray<NSString *> *directories = [original_NSSearchPathForDirectoriesInDomains(directory, domainMask, expandTilde) mutableCopy];
        [directories enumerateObjectsUsingBlock:^(NSString * _Nonnull object, NSUInteger index, BOOL * _Nonnull stop) {
            switch (directory) {
                case NSDocumentDirectory: directories[index] = [NSHomeDirectory() stringByAppendingPathComponent:@"/Library/Containers/com.tencent.xinWeChat/Data/Documents"]; break;
                case NSLibraryDirectory: directories[index] = [NSHomeDirectory() stringByAppendingPathComponent:@"/Library/Containers/com.tencent.xinWeChat/Data/Library"]; break;
                case NSApplicationSupportDirectory: directories[index] = [NSHomeDirectory() stringByAppendingPathComponent:@"/Library/Containers/com.tencent.xinWeChat/Data/Library/Application Support"]; break;
                case NSCachesDirectory: directories[index] = [NSHomeDirectory() stringByAppendingPathComponent:@"/Library/Containers/com.tencent.xinWeChat/Data/Library/Caches"]; break;
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
    rebind_symbols((struct rebinding[1]) {
        { "NSSearchPathForDirectoriesInDomains", tweak_NSSearchPathForDirectoriesInDomains, (void *)&original_NSSearchPathForDirectoriesInDomains }
    }, 1);
    // Method Swizzling
    class_addMethod(objc_getClass("AppDelegate"), @selector(applicationDockMenu:), method_getImplementation(class_getInstanceMethod(objc_getClass("AppDelegate"), @selector(tweak_applicationDockMenu:))), "@:@");
    [objc_getClass("AppDelegate") jr_swizzleMethod:NSSelectorFromString(@"applicationDidFinishLaunching:") withMethod:@selector(tweak_applicationDidFinishLaunching:) error:nil];
    [objc_getClass("AppDelegate") jr_swizzleMethod:NSSelectorFromString(@"applicationShouldTerminate:") withMethod:@selector(tweak_applicationShouldTerminate:) error:nil];
    [objc_getClass("MessageService") jr_swizzleMethod:NSSelectorFromString(@"onRevokeMsg:") withMethod:@selector(tweak_onRevokeMsg:) error:nil];
    [objc_getClass("CUtility") jr_swizzleClassMethod:NSSelectorFromString(@"HasWechatInstance") withClassMethod:@selector(tweak_HasWechatInstance) error:nil];
    [objc_getClass("MASPreferencesWindowController") jr_swizzleMethod:NSSelectorFromString(@"initWithViewControllers:") withMethod:@selector(tweak_initWithViewControllers:) error:nil];
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
    [[AlfredManager sharedInstance] startListener];
}

- (NSApplicationTerminateReply)tweak_applicationShouldTerminate:(NSApplication *)sender {
    BOOL enabledAutoAuth = [[NSUserDefaults standardUserDefaults] boolForKey:WeChatTweakPreferenceAutoAuthKey];
    if (enabledAutoAuth) {
        return NSTerminateNow;
    } else {
        return [self tweak_applicationShouldTerminate:sender];
    }
}

#pragma mark - Preferences Window

- (id)tweak_initWithViewControllers:(NSArray *)arg1 {
    NSMutableArray *viewControllers = [NSMutableArray arrayWithArray:arg1];
    TweakPreferecesController *controller = [[TweakPreferecesController alloc] initWithNibName:nil bundle:[NSBundle tweakBundle]];
    [viewControllers addObject:controller];
    return [self tweak_initWithViewControllers:viewControllers];
}

@end
