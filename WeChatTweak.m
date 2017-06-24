#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <objc/message.h>
#import <Cocoa/Cocoa.h>
#import "JRSwizzle.h"
#import "WeChatTweakHeaders.h"

@implementation NSString (WeChatTweak)

- (NSString *)tweak_sessionFromMessage {
    NSRange begin = [self rangeOfString:@"<session>"];
    NSRange end = [self rangeOfString:@"</session>"];
    NSRange range = NSMakeRange(begin.location + begin.length,end.location - begin.location - begin.length);
    return [self substringWithRange:range];
}

- (NSUInteger)tweak_newMessageIDFromMessage {
    NSRange begin = [self rangeOfString:@"<newmsgid>"];
    NSRange end = [self rangeOfString:@"</newmsgid>"];
    NSRange range = NSMakeRange(begin.location + begin.length,end.location - begin.location - begin.length);
    return [[self substringWithRange:range] longLongValue];
}

- (NSString *)tweak_replaceMessageFromMessage {
    NSRange begin = [self rangeOfString:@"<replacemsg><![CDATA["];
    NSRange end = [self rangeOfString:@"]]></replacemsg>"];
    NSRange range = NSMakeRange(begin.location + begin.length,end.location - begin.location - begin.length);
    return [self substringWithRange:range];
}

@end

@implementation NSObject (WeChatTweak)

#pragma mark - Constructor

static void __attribute__((constructor)) tweak(void) {
    class_addMethod(objc_getClass("AppDelegate"), @selector(applicationDockMenu:), method_getImplementation(class_getInstanceMethod(objc_getClass("AppDelegate"), @selector(tweak_applicationDockMenu:))), "@:@");
    [objc_getClass("AppDelegate") jr_swizzleMethod:NSSelectorFromString(@"applicationDidFinishLaunching:") withMethod:@selector(tweak_applicationDidFinishLaunching:) error:nil];
    [objc_getClass("AppDelegate") jr_swizzleMethod:NSSelectorFromString(@"applicationShouldTerminate:") withMethod:@selector(tweak_applicationShouldTerminate:) error:nil];
    [objc_getClass("MessageService") jr_swizzleMethod:NSSelectorFromString(@"onRevokeMsg:") withMethod:@selector(tweak_onRevokeMsg:) error:nil];
    [objc_getClass("CUtility") jr_swizzleClassMethod:NSSelectorFromString(@"HasWechatInstance") withClassMethod:@selector(tweak_HasWechatInstance) error:nil];
}

#pragma mark - No Revoke Message

- (void)tweak_onRevokeMsg:(NSString *)message {
    // Decode message
    NSString *session = [message tweak_sessionFromMessage];
    NSUInteger newMessageID = [message tweak_newMessageIDFromMessage];
    NSString *replaceMessage = [message tweak_replaceMessageFromMessage];

    // Prepare message data
    MessageData *localMessageData = [((MessageService *)self) GetMsgData:session svrId:newMessageID];
    MessageData *promptMessageData = ({
        MessageData *data = [[objc_getClass("MessageData") alloc] init];
        data.messageType = 10000;
        data.msgStatus = 4;
        data.toUsrName = localMessageData.toUsrName;
        data.fromUsrName = localMessageData.fromUsrName;
        data.msgCreateTime = localMessageData.msgCreateTime;
        if ([localMessageData isSendFromSelf]) {
            data.mesLocalID = localMessageData.mesLocalID;
            data.msgContent = replaceMessage;
        } else {
            data.mesLocalID = localMessageData.mesLocalID + 1;
            data.msgContent = [NSString stringWithFormat:@"[已拦截]\n%@", replaceMessage];
        }
        data;
    });

    // Prepare notification information
    NSUserNotification *userNotification = [[NSUserNotification alloc] init];
    if ([session rangeOfString:@"@chatroom"].location == NSNotFound) {
        userNotification.informativeText = replaceMessage;
    } else {
        GroupStorage *groupStorage = [[objc_getClass("MMServiceCenter") defaultCenter] getService:objc_getClass("GroupStorage")];
        WCContactData *groupContact = [groupStorage GetGroupContact: session];
        NSString *groupName = groupContact.m_nsNickName.length ? groupContact.m_nsNickName : @"群组";
        userNotification.informativeText = [NSString stringWithFormat:@"%@: %@", groupName, replaceMessage];
    }

    // Dispatch notification
    dispatch_async(dispatch_get_main_queue(), ^{
        // Delete message if is revoke from myself
        if ([localMessageData isSendFromSelf]) {
            [((MessageService *)self) DelMsg:session msgList:@[localMessageData] isDelAll:NO isManual:YES];
            [((MessageService *)self) AddRevokePromptMsg:session msgData: promptMessageData];
        } else {
            [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:userNotification];
            [((MessageService *)self) AddRevokePromptMsg:session msgData: promptMessageData];
            [((MessageService *)self) notifyAddMsgOnMainThread:session msgData: promptMessageData];
        }
    });
}

#pragma mark - Mutiple Instance

+ (BOOL)tweak_HasWechatInstance {
    return NO;
}

- (NSMenu *)tweak_applicationDockMenu:(NSApplication *)sender {
    NSMenu *menu = [[objc_getClass("NSMenu") alloc] init];
    NSMenuItem *menuItem = [[objc_getClass("NSMenuItem") alloc] initWithTitle:@"登录新的微信账号" action:@selector(openNewWeChatInstace:) keyEquivalent:@""];
    [menu insertItem:menuItem atIndex:0];
    return menu;
}

- (void)openNewWeChatInstace:(id)sender {
    NSString *applicationPath = [[objc_getClass("NSBundle") mainBundle] bundlePath];
    NSTask *task = [[objc_getClass("NSTask") alloc] init];
    task.launchPath = @"/usr/bin/open";
    task.arguments = @[@"-n", applicationPath];
    [task launch];
}

#pragma mark - Auto auth

- (void)tweak_applicationDidFinishLaunching:(NSNotification *)notification {
    [self tweak_applicationDidFinishLaunching:notification];
    NSBundle *bundle = [objc_getClass("NSBundle") mainBundle];
    NSString *bundleIdentifier = [bundle bundleIdentifier];
    NSArray *instances = [objc_getClass("NSRunningApplication") runningApplicationsWithBundleIdentifier:bundleIdentifier];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wobjc-method-access"
    if (instances.count == 1) {
        id serviceCenter = [objc_getClass("MMServiceCenter") defaultCenter];
        id accountService = [serviceCenter getService:objc_getClass("AccountService")];
        if ([accountService canAutoAuth]) {
            [accountService AutoAuth];
        }
    }
#pragma clang diagnostic pop
}

- (NSApplicationTerminateReply)tweak_applicationShouldTerminate:(NSApplication *)sender {
    return NSTerminateNow;
}

@end
