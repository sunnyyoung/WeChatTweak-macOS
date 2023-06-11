//
//  AntiRevoke.m
//  WeChatTweak
//
//  Created by Sunny Young on 2021/5/9.
//  Copyright © 2021 Sunnyyoung. All rights reserved.
//

#import "WeChatTweak.h"
#import "NSBundle+WeChatTweak.h"

@implementation NSObject (AntiRevoke)

static void __attribute__((constructor)) tweak(void) {
    [objc_getClass("FFProcessReqsvrZZ") jr_swizzleMethod:NSSelectorFromString(@"processNewXMLMsg:sessionMsgList:") withMethod:@selector(tweak_processNewXMLMsg:sessionMsgList:) error:nil];

    [objc_getClass("MMMessageCellView") jr_swizzleMethod:NSSelectorFromString(@"initWithFrame:") withMethod:@selector(tweak_initWithFrame:) error:nil];
    [objc_getClass("MMMessageCellView") jr_swizzleMethod:NSSelectorFromString(@"populateWithMessage:") withMethod:@selector(tweak_populateWithMessage:) error:nil];
    [objc_getClass("MMMessageCellView") jr_swizzleMethod:NSSelectorFromString(@"layout") withMethod:@selector(tweak_layout) error:nil];
}

- (void)tweak_processNewXMLMsg:(MessageData *)message sessionMsgList:(nullable id)sessionMsgList {
    // - (id)GetMsgData:(id)arg1 svrId:(unsigned long long)arg2;
    SEL GetMsgDataSelector = NSSelectorFromString(@"GetMsgData:svrId:");
    if (![self respondsToSelector:GetMsgDataSelector]) {
        // Fallback to origin method
        return [self tweak_processNewXMLMsg:message sessionMsgList:sessionMsgList];
    }
    // Decode message
    NSString *content = [[message.msgContent stringByReplacingOccurrencesOfString:@"\n" withString:@""] componentsSeparatedByString:@":"].lastObject;
    NSDictionary *dictionary = [NSDictionary dictionaryWithXMLString:content];
    NSString *session = dictionary[@"revokemsg"][@"session"];
    NSString *newMessageID = dictionary[@"revokemsg"][@"newmsgid"];
    NSString *replaceMessage = dictionary[@"revokemsg"][@"replacemsg"];
    // Get message data
    MessageData *messageData = ((id (*)(id, SEL, id, unsigned long long))objc_msgSend)(self, GetMsgDataSelector, session, newMessageID.longLongValue);
    if (messageData.isSendFromSelf) {
        // Fallback to origin method
        [self tweak_processNewXMLMsg:message sessionMsgList:sessionMsgList];
    } else {
        [self handleRevokedMessageIntoWithSession:session messageData:messageData replaceMessage:replaceMessage];
    }
}

- (void)handleRevokedMessageIntoWithSession:(NSString *)session messageData:(MessageData *)messageData replaceMessage:(NSString *)replaceMessage {
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
        WeChatTweakNotificationType notificationType = WeChatTweak.notificationType;
        if (notificationType == WeChatTweakNotificationTypeReceiveAll || (notificationType == WeChatTweakNotificationTypeInherited && isChatStatusNotifyOpen)) {
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
    revokeTextField.stringValue = [NSBundle.tweakBundle localizedStringForKey:@"Tweak.Message.RecalledMark"];
    revokeTextField.font = [NSFont systemFontOfSize:7.0];
    revokeTextField.textColor = [NSColor lightGrayColor];
    [revokeTextField sizeToFit];
    [view addSubview:revokeTextField];
    return view;
}

- (void)tweak_populateWithMessage:(MMMessageTableItem *)tableItem {
    [self tweak_populateWithMessage:tableItem];
    MMRevokeMsgService *service = [[objc_getClass("MMServiceCenter") defaultCenter] getService:objc_getClass("MMRevokeMsgService")];
    BOOL recalled = tableItem.message ? (tableItem.message.messageType != MessageDataTypePrompt && tableItem.message.msgStatus == 4 && [service.db getRevokeMsg:@(tableItem.message.mesSvrID).stringValue] != NULL) : NO;
    [((MMMessageCellView *)self).subviews enumerateObjectsUsingBlock:^(__kindof NSView * _Nonnull view, NSUInteger index, BOOL * _Nonnull stop) {
        if (view.tag != 9527) {
            return ;
        }
        *stop = YES;
        view.hidden = !recalled;
    }];
    ((MMMessageCellView *)self).layer.backgroundColor = recalled ? WeChatTweak.maskColor.CGColor : nil;
}

- (void)tweak_layout {
    [self tweak_layout];
    [((MMMessageCellView *)self).subviews enumerateObjectsUsingBlock:^(__kindof NSView * _Nonnull view, NSUInteger index, BOOL * _Nonnull stop) {
        if (view.tag != 9527) {
            return;
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
