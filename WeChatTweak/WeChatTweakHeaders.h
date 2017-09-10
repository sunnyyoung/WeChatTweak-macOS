//
//  WeChatTweakHeaders.h
//  WeChatTweak
//
//  Created by Sunnyyoung on 2017/8/11.
//  Copyright © 2017年 Sunnyyoung. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>

@interface WeChat : NSObject

+ (instancetype)sharedInstance;
- (void)lock:(id)block;
- (void)showMainWindow;
- (void)startANewChatWithContact:(id)contact;

@end

@interface MMSearchResultItem : NSObject

@property(nonatomic) unsigned long long type; // 0 is single chat, 1 is group chat
@property(readonly, nonatomic) NSString *identifier;

@end

@interface MessageData: NSObject

@property(nonatomic) unsigned int messageType;
@property(nonatomic) unsigned int msgStatus;
@property(retain, nonatomic) NSString *toUsrName;
@property(retain, nonatomic) NSString *fromUsrName;
@property(retain, nonatomic) NSString *msgContent;
@property(nonatomic) unsigned int msgCreateTime;
@property(nonatomic) unsigned int mesLocalID;

- (BOOL)isSendFromSelf;

@end

@interface WCContactData : NSObject

@property(nonatomic) unsigned int m_uiBrandSubscriptionSettings;
@property(retain, nonatomic) NSString *m_nsNickName;
@property(retain, nonatomic) NSString *m_nsUsrName;
@property(retain, nonatomic) NSString *m_nsAliasName;
@property(retain, nonatomic) NSString *m_nsRemark;
@property(retain, nonatomic) NSString *m_nsFullPY;
@property(retain, nonatomic) NSString *m_nsRemarkPYShort;
@property(retain, nonatomic) NSString *m_nsRemarkPYFull;

- (BOOL)isChatStatusNotifyOpen;

@end

@interface ContactStorage : NSObject

- (WCContactData *)GetContact:(NSString *)session;
- (NSArray<WCContactData *> *)GetAllFriendContacts;

@end

@interface GroupStorage: NSObject

- (WCContactData *)GetGroupContact:(NSString *)session;
- (NSArray<WCContactData *> *)GetAllGroups;

@end

@interface MMServiceCenter : NSObject

+ (id)defaultCenter;
- (id)getService:(Class)name;

@end

@interface MessageService: NSObject

- (id)GetMsgData:(id)arg1 svrId:(unsigned long long)arg2;
- (void)DelMsg:(id)arg1 msgList:(id)arg2 isDelAll:(BOOL)arg3 isManual:(BOOL)arg4;
- (void)AddLocalMsg:(id)arg1 msgData:(id)arg2;
- (void)notifyAddMsgOnMainThread:(id)arg1 msgData:(id)arg2;

@end

@interface AccountService: NSObject

- (BOOL)canAutoAuth;
- (void)AutoAuth;

@end

@protocol MASPreferencesViewController <NSObject>

@property(readonly, nonatomic) NSString *toolbarItemLabel;
@property(readonly, nonatomic) NSImage *toolbarItemImage;
@property(readonly, nonatomic) NSString *identifier;

@optional
@property(readonly, nonatomic) BOOL hasResizableHeight;
@property(readonly, nonatomic) BOOL hasResizableWidth;

@end

@interface MASPreferencesWindowController : NSWindowController

- (id)initWithViewControllers:(NSArray *)arg1;

@end
