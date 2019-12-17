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
#import "TweakPreferencesController.h"
#import "AlfredManager.h"
#import "WTConfigManager.h"
#import "RecallCacheManager.h"

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
    [objc_getClass("LogoutCGI") jr_swizzleMethod:NSSelectorFromString(@"FFVCRecvDataAddDataToMsgChatMgrRecvZZ:") withMethod:@selector(tweak_sendLogoutCGIWithCompletion:) error:nil];
    [objc_getClass("AccountService") jr_swizzleMethod:NSSelectorFromString(@"onAuthOKOfUser:withSessionKey:withServerId:autoAuthKey:isAutoAuth:") withMethod:@selector(tweak_onAuthOKOfUser:withSessionKey:withServerId:autoAuthKey:isAutoAuth:) error:nil];
    [objc_getClass("AccountService") jr_swizzleMethod:NSSelectorFromString(@"ManualLogout") withMethod:@selector(tweak_ManualLogout) error:nil];
    [objc_getClass("AccountService") jr_swizzleMethod:NSSelectorFromString(@"FFAddSvrMsgImgVCZZ") withMethod:@selector(tweak_ManualLogout) error:nil];
    [objc_getClass("MessageService") jr_swizzleMethod:NSSelectorFromString(@"onRevokeMsg:") withMethod:@selector(tweak_onRevokeMsg:) error:nil];
    [objc_getClass("MessageService") jr_swizzleMethod:NSSelectorFromString(@"FFToNameFavChatZZ:") withMethod:@selector(tweak_onRevokeMsg:) error:nil];
    [objc_getClass("MessageService") jr_swizzleMethod:NSSelectorFromString(@"FFToNameFavChatZZ:sessionMsgList:") withMethod:@selector(tweak_onRevokeMsg:sessionMessageList:) error:nil];
    [objc_getClass("CUtility") jr_swizzleClassMethod:NSSelectorFromString(@"HasWechatInstance") withClassMethod:@selector(tweak_HasWechatInstance) error:nil];
    [objc_getClass("CUtility") jr_swizzleClassMethod:NSSelectorFromString(@"FFSvrChatInfoMsgWithImgZZ") withClassMethod:@selector(tweak_HasWechatInstance) error:nil];
    [objc_getClass("NSRunningApplication") jr_swizzleClassMethod:NSSelectorFromString(@"runningApplicationsWithBundleIdentifier:") withClassMethod:@selector(tweak_runningApplicationsWithBundleIdentifier:) error:nil];
    [objc_getClass("MASPreferencesWindowController") jr_swizzleMethod:NSSelectorFromString(@"initWithViewControllers:") withMethod:@selector(tweak_initWithViewControllers:) error:nil];
    
    [objc_getClass("MMMessageCellView") jr_swizzleMethod:NSSelectorFromString(@"contextMenu") withMethod:@selector(tweak_contextMenu) error:nil];
    [objc_getClass("MMMessageCellView") jr_swizzleMethod:NSSelectorFromString(@"initWithFrame:") withMethod:@selector(tweak_initWithFrame:) error:nil];
    [objc_getClass("MMMessageCellView") jr_swizzleMethod:NSSelectorFromString(@"populateWithMessage:") withMethod:@selector(tweak_populateWithMessage:) error:nil];
    [objc_getClass("MMMessageCellView") jr_swizzleMethod:NSSelectorFromString(@"layout") withMethod:@selector(tweak_layout) error:nil];
    
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

- (instancetype)tweak_initWithFrame:(NSRect)arg1 {
    MMMessageCellView *view = (MMMessageCellView *)[self tweak_initWithFrame:arg1];
    NSTextField *revokeTextField = [[NSTextField alloc] init];
    revokeTextField.hidden = YES;
    revokeTextField.editable = NO;
    revokeTextField.selectable = NO;
    revokeTextField.bordered = NO;
    revokeTextField.drawsBackground = NO;
    revokeTextField.usesSingleLineMode = YES;
    revokeTextField.tag = 9527;
    revokeTextField.stringValue = @"[已撤回]";
    revokeTextField.font = [NSFont systemFontOfSize:10];
    revokeTextField.textColor = [NSColor lightGrayColor];
    [view addSubview:revokeTextField];
    return view;
}

- (void)tweak_populateWithMessage:(MMMessageTableItem *)tableItem {
    [self tweak_populateWithMessage:tableItem];
    BOOL style = [RecallCacheManager containsRevokedMessage:tableItem.message] && tableItem.message.messageType != MessageDataTypePrompt;
    [((MMMessageCellView *)self).subviews enumerateObjectsUsingBlock:^(__kindof NSView * _Nonnull view, NSUInteger index, BOOL * _Nonnull stop) {
        if (view.tag != 9527) {
            return ;
        }
        *stop = YES;
        view.hidden = !style;
    }];
    ((MMMessageCellView *)self).layer.backgroundColor = style ? [NSColor.yellowColor colorWithAlphaComponent:0.3].CGColor : ((MMMessageCellView *)self).layer.backgroundColor;
}

- (void)tweak_layout {
    [self tweak_layout];
    __block NSTextField *label = nil;
    [((MMMessageCellView *)self).subviews enumerateObjectsUsingBlock:^(__kindof NSView * _Nonnull view, NSUInteger index, BOOL * _Nonnull stop) {
        if (view.tag != 9527) {
            return ;
        }
        *stop = YES;
        label = view;
    }];
    if (label == nil) {
        return;
    }
    label.frame = ({
        NSView *avatarView = ((MMMessageCellView *)self).avatarImgView;
        CGFloat x = CGRectGetMidX(avatarView.frame) - CGRectGetWidth(label.frame) / 2.0;
        CGFloat y = CGRectGetMinY(avatarView.frame) - CGRectGetHeight(label.frame);
        NSRect fuck = [label.stringValue boundingRectWithSize:NSMakeSize(CGFLOAT_MAX, CGFLOAT_MAX) options:kNilOptions attributes:nil];
        NSRect frame = NSMakeRect(x, y, CGRectGetWidth(fuck), CGRectGetHeight(fuck));
        frame;
    });
}

#pragma mark - No Revoke Message

- (void)tweak_onRevokeMsg:(MessageData *)message {
    [self tweak_onRevokeMsg:message sessionMessageList:nil];
}

- (void)tweak_onRevokeMsg:(MessageData *)message sessionMessageList:(nullable id)sessionMessageList {
    switch (WTConfigManager.sharedInstance.revokedMessageStyle) {
        case WTRevokedMessageStylePlain:
            [self handleRevokedMessageIntoClassicStyle:message]; break;
        case WTRevokedMessageStyleMask:
            [self handleRevokedMessageIntoMaskStyle:message]; break;
        default:
            break;
    }
}

- (void)handleRevokedMessageIntoClassicStyle:(MessageData *)message {
    // Decode message
    NSString *session = [message.msgContent tweak_subStringFrom:@"<session>" to:@"</session>"];
    NSUInteger newMessageID = [message.msgContent tweak_subStringFrom:@"<newmsgid>" to:@"</newmsgid>"].longLongValue;
    NSString *replaceMessage = [message.msgContent tweak_subStringFrom:@"<replacemsg><![CDATA[" to:@"]]></replacemsg>"];
    // Prepare message data
    MessageData *localMessageData = [((MessageService *)self) GetMsgData:session svrId:newMessageID];
    MessageData *promptMessageData = ({
        MessageData *data = [[objc_getClass("MessageData") alloc] initWithMsgType:10000];
        data.msgStatus = 4;
        data.toUsrName = localMessageData.toUsrName;
        data.fromUsrName = localMessageData.fromUsrName;
        data.mesSvrID = localMessageData.mesSvrID;
        data.mesLocalID = localMessageData.mesLocalID;
        data.msgCreateTime = localMessageData.msgCreateTime;
        if ([localMessageData isSendFromSelf]) {
            data.msgContent = replaceMessage;
        } else {
            NSString *fromUserName = [replaceMessage componentsSeparatedByString:@" "].firstObject;
            NSString *userRevoke = [NSString stringWithFormat:@"%@ %@ ", fromUserName, [NSBundle.tweakBundle localizedStringForKey:@"Tweak.Message.Recalled"]];
            NSString *tips = [NSString stringWithFormat:[NSBundle.tweakBundle localizedStringForKey:@"Tweak.Message.InterceptedARecalledMessage"], userRevoke];
            NSMutableString *msgContent = [NSMutableString stringWithString:tips];
            switch (localMessageData.messageType) {
                case MessageDataTypeText: {
                    if (localMessageData.msgContent.length) {
                        if ([session rangeOfString:@"@chatroom"].location == NSNotFound) {
                            [msgContent appendFormat:@"\"%@\"", localMessageData.msgContent];
                        } else {
                            [msgContent appendFormat:@"\"%@\"", [localMessageData.msgContent componentsSeparatedByString:@":\n"].lastObject];
                        }
                    } else {
                        [msgContent appendString:[NSBundle.tweakBundle localizedStringForKey:@"Tweak.Message.AMessage"]];
                    }
                    break;
                }
                case MessageDataTypeImage:
                    [msgContent appendFormat:@"<%@>", [NSBundle.tweakBundle localizedStringForKey:@"Tweak.Message.Image"]]; break;
                case MessageDataTypeVoice:
                    [msgContent appendFormat:@"<%@>", [NSBundle.tweakBundle localizedStringForKey:@"Tweak.Message.Voice"]]; break;
                case MessageDataTypeVideo:
                    [msgContent appendFormat:@"<%@>", [NSBundle.tweakBundle localizedStringForKey:@"Tweak.Message.Video"]]; break;
                case MessageDataTypeSticker:
                    [msgContent appendFormat:@"<%@>", [NSBundle.tweakBundle localizedStringForKey:@"Tweak.Message.Sticker"]]; break;
                case MessageDataTypeAppUrl:
                    [msgContent appendFormat:@"<%@>", [NSBundle.tweakBundle localizedStringForKey:@"Tweak.Message.Link"]]; break;
                default:
                    [msgContent appendString:[NSBundle.tweakBundle localizedStringForKey:@"Tweak.Message.AMessage"]]; break;
            }
            data.msgContent = msgContent;
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
        NSString *groupName = groupContact.m_nsNickName.length ? groupContact.m_nsNickName : [NSBundle.tweakBundle localizedStringForKey:@"Tweak.Title.Group"];
        userNotification.informativeText = [NSString stringWithFormat:@"%@: %@", groupName, replaceMessage];
    }
    // Delete message if it is revoke from myself
    if ([localMessageData isSendFromSelf]) {
        [((MessageService *)self) DelMsg:session msgList:@[localMessageData] isDelAll:NO isManual:YES];
        [((MessageService *)self) AddLocalMsg:session msgData:promptMessageData];
    } else {
        if (localMessageData.messageType == MessageDataTypeText) {
            [((MessageService *)self) DelMsg:session msgList:@[localMessageData] isDelAll:NO isManual:YES];
        }
        [((MessageService *)self) AddLocalMsg:session msgData:promptMessageData];
    }
    // Dispatch notification
    dispatch_async(dispatch_get_main_queue(), ^{
        // Deliver notification
        if (![localMessageData isSendFromSelf]) {
            RevokeNotificationType notificationType = [[NSUserDefaults standardUserDefaults] integerForKey:WeChatTweakPreferenceRevokeNotificationTypeKey];
            if (notificationType == RevokeNotificationTypeReceiveAll || (notificationType == RevokeNotificationTypeFollow && isChatStatusNotifyOpen)) {
                [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:userNotification];
            }
        }
    });
}

- (void)handleRevokedMessageIntoMaskStyle:(MessageData *)message {
    // Decode message
    NSString *session = [message.msgContent tweak_subStringFrom:@"<session>" to:@"</session>"];
    NSUInteger newMessageID = [message.msgContent tweak_subStringFrom:@"<newmsgid>" to:@"</newmsgid>"].longLongValue;
    NSString *replaceMessage = [message.msgContent tweak_subStringFrom:@"<replacemsg><![CDATA[" to:@"]]></replacemsg>"];
    // Get message data
    MessageData *messageData = [((MessageService *)self) GetMsgData:session svrId:newMessageID];
    [RecallCacheManager insertRevokedMessage:messageData];
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
        NSString *groupName = groupContact.m_nsNickName.length ? groupContact.m_nsNickName : [NSBundle.tweakBundle localizedStringForKey:@"Tweak.Title.Group"];
        userNotification.informativeText = [NSString stringWithFormat:@"%@: %@", groupName, replaceMessage];
    }
    if ([messageData isSendFromSelf]) {
        MessageData *promptMessageData = ({
            MessageData *data = [[objc_getClass("MessageData") alloc] initWithMsgType:MessageDataTypePrompt];
            data.msgStatus = 4;
            data.toUsrName = messageData.toUsrName;
            data.fromUsrName = messageData.fromUsrName;
            data.mesSvrID = messageData.mesSvrID;
            data.mesLocalID = messageData.mesLocalID;
            data.msgCreateTime = messageData.msgCreateTime;
            data.msgContent = replaceMessage;
            data;
        });
        // Delete message if it is revoke from myself
        [((MessageService *)self) DelMsg:session msgList:@[messageData] isDelAll:NO isManual:YES];
        [((MessageService *)self) AddLocalMsg:session msgData:promptMessageData];
    } else {
        // Invoke message reloading
        [((MessageService *)self) notifyDelMsgOnMainThread:messageData.getChatNameForCurMsg msgData:messageData];
        [((MessageService *)self) notifyAddRevokePromptMsgOnMainThread:messageData.getChatNameForCurMsg msgData:messageData];
    }
    // Dispatch notification
    dispatch_async(dispatch_get_main_queue(), ^{
        // Deliver notification
        if (![messageData isSendFromSelf]) {
            RevokeNotificationType notificationType = [[NSUserDefaults standardUserDefaults] integerForKey:WeChatTweakPreferenceRevokeNotificationTypeKey];
            if (notificationType == RevokeNotificationTypeReceiveAll || (notificationType == RevokeNotificationTypeFollow && isChatStatusNotifyOpen)) {
                [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:userNotification];
            }
        }
    });
}

#pragma mark - AppUrlMessageMenu

- (id)tweak_contextMenu {
    NSMenu *menu = (NSMenu *)[self tweak_contextMenu];
    MMMessageCellView *view = (MMMessageCellView *)self;
    if (view.messageTableItem.message.messageType == MessageDataTypeAppUrl) {
        [menu addItem:[NSMenuItem separatorItem]];
        [menu addItem:({
            NSMenuItem *copyUrlItem = [[NSMenuItem alloc] initWithTitle:[NSBundle.tweakBundle localizedStringForKey:@"Tweak.MessageMenuItem.CopyLink"] action:@selector(tweakCopyUrl:) keyEquivalent:@""];
            copyUrlItem;
        })];
        [menu addItem:({
            NSMenuItem *openUrlItem = [[NSMenuItem alloc] initWithTitle:[NSBundle.tweakBundle localizedStringForKey:@"Tweak.MessageMenuItem.OpenInBrowser"] action:@selector(tweakOpenUrlItem:) keyEquivalent:@""];
            openUrlItem;
        })];
    } else if (view.messageTableItem.message.messageType == MessageDataTypeImage) {
        [menu addItem:[NSMenuItem separatorItem]];
        [menu addItem:({
            NSMenuItem *qrCodeItem = [[NSMenuItem alloc] initWithTitle:[NSBundle.tweakBundle localizedStringForKey:@"Tweak.MessageMenuItem.IdentifyQRCode"] action:@selector(tweakIdentifyQRCode:) keyEquivalent:@""];
            qrCodeItem;
        })];
    }
    return menu;
}

- (void)tweakCopyUrl:(id)sender {
    NSString *url = [self _tweakMessageContentUrl];
    if (url.length) {
        [[NSPasteboard generalPasteboard] clearContents];
        [[NSPasteboard generalPasteboard] setString:url forType:NSStringPboardType];
    }
}

- (void)tweakOpenUrlItem:(id)sender {
    NSString *url = [self _tweakMessageContentUrl];
    if (url.length) {
        [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:url]];
    }
}

- (void)tweakIdentifyQRCode:(id)sender {
    MMImageMessageCellView *cell = (MMImageMessageCellView *)self;
    NSImage *image = cell.displayedImage;
    if (image) {
        NSData *imageData = [image TIFFRepresentation];
        CIDetector *detector = [CIDetector detectorOfType:CIDetectorTypeQRCode context:nil options:@{CIDetectorAccuracy: CIDetectorAccuracyHigh}];
        NSArray *results = [detector featuresInImage:[CIImage imageWithData:imageData]];
        if (results.count) {
            CIQRCodeFeature *result = results.firstObject;
            NSString *content = result.messageString;
            if (content.length) {
                NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
                [pasteboard clearContents];
                [pasteboard setString:content forType:NSStringPboardType];
                [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:({
                    NSUserNotification *notification = [[NSUserNotification alloc] init];
                    notification.informativeText = [NSBundle.tweakBundle localizedStringForKey:@"Tweak.MessageMenuItem.IdentifyQRCodeNotification"];
                    notification;
                })];
                NSURL *url = [NSURL URLWithString:content];
                if ([url.scheme containsString:@"http"]) {
                    [[NSWorkspace sharedWorkspace] openURL:url];
                }
            }
        }
    }
}

- (NSString *)_tweakMessageContentUrl {
    MMMessageCellView *cell = (MMMessageCellView *)self;
    NSString *content = cell.messageTableItem.message.msgContent;
    if ([content containsString:@"<url><![CDATA["]) {
        return [content tweak_subStringFrom:@"<url><![CDATA[" to:@"]]></url>"];
    } else {
        return [content tweak_subStringFrom:@"<url>" to:@"</url>"];
    }
}

#pragma mark - Mutiple Instance

+ (BOOL)tweak_HasWechatInstance {
    return NO;
}

+ (NSArray<NSRunningApplication *> *)tweak_runningApplicationsWithBundleIdentifier:(NSString *)bundleIdentifier {
    if ([bundleIdentifier isEqualToString:NSBundle.mainBundle.bundleIdentifier]) {
        return @[NSRunningApplication.currentApplication];
    } else {
        return [self tweak_runningApplicationsWithBundleIdentifier:bundleIdentifier];
    }
}

- (NSMenu *)tweak_applicationDockMenu:(NSApplication *)sender {
    NSMenu *menu = [[NSMenu alloc] init];
    NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:[NSBundle.tweakBundle localizedStringForKey:@"Tweak.Title.LoginAnotherAccount"]
                                                      action:@selector(openNewWeChatInstace:)
                                               keyEquivalent:@""];
    [menu insertItem:menuItem atIndex:0];
    return menu;
}

- (void)openNewWeChatInstace:(id)sender {
    NSString *applicationPath = NSBundle.mainBundle.bundlePath;
    NSTask *task = [[NSTask alloc] init];
    task.launchPath = @"/usr/bin/open";
    task.arguments = @[@"-n", applicationPath];
    [task launch];
}

#pragma mark - Auto Auth

- (void)tweak_applicationDidFinishLaunching:(NSNotification *)notification {
    [self tweak_applicationDidFinishLaunching:notification];
    NSString *bundleIdentifier = NSBundle.mainBundle.bundleIdentifier;
    NSArray *instances = [NSRunningApplication tweak_runningApplicationsWithBundleIdentifier:bundleIdentifier];
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
    TweakPreferencesController *controller = [[TweakPreferencesController alloc] initWithNibName:nil bundle:[NSBundle tweakBundle]];
    [viewControllers addObject:controller];
    return [self tweak_initWithViewControllers:viewControllers];
}

#pragma mark - WCContact Data

- (NSString *)wt_avatarPath {
    if (![objc_getClass("PathUtility") respondsToSelector:@selector(GetCurUserDocumentPath)]) {
        return @"";
    }
    NSString *pathString = [NSString stringWithFormat:@"%@/Avatar/%@.jpg", [objc_getClass("PathUtility") GetCurUserDocumentPath], [((WCContactData *)self).m_nsUsrName md5String]];
    return [NSFileManager.defaultManager fileExistsAtPath:pathString] ? pathString : @"";
}

- (void)setWt_avatarPath:(NSString *)avatarPath {
    // For readonly
    return;
}

+ (NSArray *)modelPropertyWhitelist {
    NSArray *list =@[@"wt_avatarPath",
                     @"m_nsRemark",
                     @"m_nsNickName",
                     @"m_nsUsrName"];
    return WTConfigManager.sharedInstance.compressedJSONEnabled ? list : nil;
}

@end
