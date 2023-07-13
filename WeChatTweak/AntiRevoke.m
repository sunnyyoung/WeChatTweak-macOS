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
    [objc_getClass("FFProcessReqsvrZZ") jr_swizzleMethod:NSSelectorFromString(@"DelRevokedMsg:msgData:") withMethod:@selector(tweak_DelRevokedMsg:msgData:) error:nil];
    [objc_getClass("FFProcessReqsvrZZ") jr_swizzleMethod:NSSelectorFromString(@"notifyAddRevokePromptMsgOnMainThread:msgData:") withMethod:@selector(tweak_notifyAddRevokePromptMsgOnMainThread:msgData:) error:nil];

    [objc_getClass("MMMessageCellView") jr_swizzleMethod:NSSelectorFromString(@"initWithFrame:") withMethod:@selector(tweak_initWithFrame:) error:nil];
    [objc_getClass("MMMessageCellView") jr_swizzleMethod:NSSelectorFromString(@"populateWithMessage:") withMethod:@selector(tweak_populateWithMessage:) error:nil];
    [objc_getClass("MMMessageCellView") jr_swizzleMethod:NSSelectorFromString(@"layout") withMethod:@selector(tweak_layout) error:nil];
}

- (void)tweak_DelRevokedMsg:(NSString *)session msgData:(MessageData *)messageData {
    if (messageData.isSendFromSelf) {
        [self tweak_DelRevokedMsg:session msgData:messageData];
    } else {
        messageData.mesSvrID = LONG_LONG_MAX;
        [((FFProcessReqsvrZZ *)self) ModifyMsgData:session msgData:messageData];
        dispatch_async(dispatch_get_main_queue(), ^{
            [((FFProcessReqsvrZZ *)self) notifyDelMsgOnMainThread:session msgData:messageData isRevoke:YES];
            [((FFProcessReqsvrZZ *)self) notifyAddMsgOnMainThread:session msgData:messageData];
        });
    }
}

- (void)tweak_notifyAddRevokePromptMsgOnMainThread:(NSString *)session msgData:(MessageData *)messageData {
    MessageData *localMessage = [((FFProcessReqsvrZZ *)self) GetMsgData:session localId:messageData.mesLocalID];
    if (!localMessage || localMessage.mesSvrID != LONG_LONG_MAX) {
        [self tweak_notifyAddRevokePromptMsgOnMainThread:session msgData:messageData];
    } else {
        MMServiceCenter *serviceCenter = [objc_getClass("MMServiceCenter") defaultCenter];
        NSUserNotification *userNotification = [[NSUserNotification alloc] init];
        BOOL isChatStatusNotifyOpen = YES;
        if ([session rangeOfString:@"@chatroom"].location == NSNotFound) {
            ContactStorage *contactStorage = [serviceCenter getService:objc_getClass("ContactStorage")];
            WCContactData *contact = [contactStorage GetContact:session];
            isChatStatusNotifyOpen = [contact isChatStatusNotifyOpen];
            userNotification.informativeText = messageData.msgContent;
        } else {
            GroupStorage *groupStorage = [serviceCenter getService:objc_getClass("GroupStorage")];
            WCContactData *groupContact = [groupStorage GetGroupContact:session];
            isChatStatusNotifyOpen = [groupContact isChatStatusNotifyOpen];
            NSString *groupName = groupContact.m_nsNickName.length ? groupContact.m_nsNickName : [NSBundle.tweakBundle localizedStringForKey:@"Tweak.Title.Group"];
            userNotification.informativeText = [NSString stringWithFormat:@"%@: %@", groupName, messageData.msgContent];
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
    BOOL recalled = tableItem.message.mesSvrID == LONG_LONG_MAX;
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
