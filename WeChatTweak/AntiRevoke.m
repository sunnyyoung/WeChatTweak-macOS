//
//  AntiRevoke.m
//  WeChatTweak
//
//  Created by Sunny Young on 2021/5/9.
//  Copyright © 2021 Sunnyyoung. All rights reserved.
//

#import "AntiRevoke.h"
#import "WeChatTweakHeaders.h"
#import "WTConfigManager.h"
#import "NSString+WeChatTweak.h"
#import "NSBundle+WeChatTweak.h"

@implementation NSObject (AntiRevoke)

static void __attribute__((constructor)) tweak(void) {
    [objc_getClass("FFProcessReqsvrZZ") jr_swizzleMethod:NSSelectorFromString(@"FFToNameFavChatZZ:sessionMsgList:") withMethod:@selector(tweak_FFToNameFavChatZZ:sessionMsgList:) error:nil];
    
    [objc_getClass("MMMessageCellView") jr_swizzleMethod:NSSelectorFromString(@"initWithFrame:") withMethod:@selector(tweak_initWithFrame:) error:nil];
    [objc_getClass("MMMessageCellView") jr_swizzleMethod:NSSelectorFromString(@"populateWithMessage:") withMethod:@selector(tweak_populateWithMessage:) error:nil];
    [objc_getClass("MMMessageCellView") jr_swizzleMethod:NSSelectorFromString(@"layout") withMethod:@selector(tweak_layout) error:nil];
}

- (void)tweak_FFToNameFavChatZZ:(MessageData *)message sessionMsgList:(nullable id)sessionMsgList {
    // - (id)GetMsgData:(id)arg1 svrId:(unsigned long long)arg2;
    SEL GetMsgDataSelector = NSSelectorFromString(@"GetMsgData:svrId:");
    if (![self respondsToSelector:GetMsgDataSelector]) {
        // Fallback to origin method
        return [self tweak_FFToNameFavChatZZ:message sessionMsgList:sessionMsgList];
    }
    // Decode message
    NSString *session = [message.msgContent tweak_subStringFrom:@"<session>" to:@"</session>"];
    NSUInteger newMessageID = [message.msgContent tweak_subStringFrom:@"<newmsgid>" to:@"</newmsgid>"].longLongValue;
    NSString *replaceMessage = [message.msgContent tweak_subStringFrom:@"<replacemsg><![CDATA[" to:@"]]></replacemsg>"];
    // Get message data
    MessageData *messageData = ((id (*)(id, SEL, id, unsigned long long))objc_msgSend)(self, GetMsgDataSelector, session, newMessageID);
    if (messageData.isSendFromSelf) {
        // Fallback to origin method
        [self tweak_FFToNameFavChatZZ:message sessionMsgList:sessionMsgList];
    } else {
        switch (WTConfigManager.sharedInstance.revokedMessageStyle) {
            case WTRevokedMessageStyleClassic:
                [self handleRevokedMessageIntoClassicStyleWithSession:session messageData:messageData replaceMessage:replaceMessage];
                break;
            case WTRevokedMessageStyleMask:
                [self handleRevokedMessageIntoMaskStyleWithSession:session messageData:messageData replaceMessage:replaceMessage];
                break;
            default:
                break;
        }
    }
}

- (void)handleRevokedMessageIntoClassicStyleWithSession:(NSString *)session messageData:(MessageData *)messageData replaceMessage:(NSString *)replaceMessage {
    // Prepare message data
    MessageData *localMessageData = messageData;
    MessageData *promptMessageData = ({
        MessageData *data = [[objc_getClass("MessageData") alloc] initWithMsgType:10000];
        data.msgStatus = 4;
        data.toUsrName = localMessageData.toUsrName;
        data.fromUsrName = localMessageData.fromUsrName;
        data.mesSvrID = localMessageData.mesSvrID;
        data.mesLocalID = localMessageData.mesLocalID;
        data.msgCreateTime = localMessageData.msgCreateTime;
        data.msgContent = ({
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
            msgContent.copy;
        });
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
    // - (void)AddLocalMsg:(id)arg1 msgData:(id)arg2;
    SEL addMsgSelector = NSSelectorFromString(@"AddLocalMsg:msgData:");
    if ([self respondsToSelector:addMsgSelector]) {
        ((void (*)(id, SEL, id, id))objc_msgSend)(self, addMsgSelector, session, promptMessageData);
    }
    // Dispatch notification
    dispatch_async(dispatch_get_main_queue(), ^{
        // Deliver notification
        RevokeNotificationType notificationType = [[NSUserDefaults standardUserDefaults] integerForKey:WeChatTweakPreferenceRevokeNotificationTypeKey];
        if (notificationType == RevokeNotificationTypeReceiveAll || (notificationType == RevokeNotificationTypeFollow && isChatStatusNotifyOpen)) {
            [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:userNotification];
        }
    });
}

- (void)handleRevokedMessageIntoMaskStyleWithSession:(NSString *)session messageData:(MessageData *)messageData replaceMessage:(NSString *)replaceMessage {
    MMRevokeMsgService *service = [[objc_getClass("MMServiceCenter") defaultCenter] getService:objc_getClass("MMRevokeMsgService")];
    [service.db insertRevokeMsg:({
        RevokeMsgItem *item = [[objc_getClass("RevokeMsgItem") alloc] init];
        item.svrId = @(messageData.mesSvrID).stringValue;
        item.createTime = UINT32_MAX;
        item;
    })];
    WeChat *wechat = [objc_getClass("WeChat") sharedInstance];
    if ([wechat respondsToSelector:NSSelectorFromString(@"chatsViewController")]) {
        id chatsViewController = [wechat valueForKey:@"chatsViewController"];
        if ([chatsViewController respondsToSelector:NSSelectorFromString(@"chatDetailSplitViewController")]) {
            id chatDetailSplitViewController = [chatsViewController valueForKey:@"chatDetailSplitViewController"];
            if ([chatDetailSplitViewController respondsToSelector:NSSelectorFromString(@"chatMessageViewController")]) {
                id chatMessageViewController = [chatDetailSplitViewController valueForKey:@"chatMessageViewController"];
                if ([chatMessageViewController respondsToSelector:NSSelectorFromString(@"reloadTableView")]) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        ((void (*)(id, SEL))objc_msgSend)(chatMessageViewController, NSSelectorFromString(@"reloadTableView"));
                    });
                }
            }
        }
    }
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
    // Dispatch notification
    dispatch_async(dispatch_get_main_queue(), ^{
        // Deliver notification
        RevokeNotificationType notificationType = [[NSUserDefaults standardUserDefaults] integerForKey:WeChatTweakPreferenceRevokeNotificationTypeKey];
        if (notificationType == RevokeNotificationTypeReceiveAll || (notificationType == RevokeNotificationTypeFollow && isChatStatusNotifyOpen)) {
            [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:userNotification];
        }
    });
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
    [revokeTextField sizeToFit];
    [view addSubview:revokeTextField];
    return view;
}

- (void)tweak_populateWithMessage:(MMMessageTableItem *)tableItem {
    [self tweak_populateWithMessage:tableItem];
    MMRevokeMsgService *service = [[objc_getClass("MMServiceCenter") defaultCenter] getService:objc_getClass("MMRevokeMsgService")];
    BOOL style = tableItem.message.messageType != MessageDataTypePrompt && [service.db getRevokeMsg:@(tableItem.message.mesSvrID).stringValue] != NULL;
    [((MMMessageCellView *)self).subviews enumerateObjectsUsingBlock:^(__kindof NSView * _Nonnull view, NSUInteger index, BOOL * _Nonnull stop) {
        if (view.tag != 9527) {
            return ;
        }
        *stop = YES;
        view.hidden = !style;
    }];
    ((MMMessageCellView *)self).layer.backgroundColor = style ? [NSColor.systemYellowColor colorWithAlphaComponent:0.3].CGColor : ((MMMessageCellView *)self).layer.backgroundColor;
}

- (void)tweak_layout {
    [self tweak_layout];
    [((MMMessageCellView *)self).subviews enumerateObjectsUsingBlock:^(__kindof NSView * _Nonnull view, NSUInteger index, BOOL * _Nonnull stop) {
        if (view.tag != 9527) {
            return ;
        }
        *stop = YES;
        view.frame = ({
            NSView *avatarView = ((MMMessageCellView *)self).avatarImgView;
            CGFloat x = CGRectGetMidX(avatarView.frame) - CGRectGetWidth(view.frame) / 2.0;
            CGFloat y = CGRectGetMinY(avatarView.frame) - CGRectGetHeight(view.frame);
            NSRect frame = NSMakeRect(x, y, CGRectGetWidth(view.frame), CGRectGetHeight(view.frame));
            frame;
        });
    }];
}

@end
