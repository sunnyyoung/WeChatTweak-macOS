//
//  WeChatTweakHeaders.h
//  WeChatTweak
//
//  Created by Sunnyyoung on 2017/8/11.
//  Copyright © 2017年 Sunnyyoung. All rights reserved.
//

#import <AppKit/AppKit.h>
#import <objc/runtime.h>
#import <objc/message.h>
#import <JRSwizzle/JRSwizzle.h>

typedef NS_ENUM(unsigned int, MessageDataType) {
    MessageDataTypeText     = 1,
    MessageDataTypeImage    = 3,
    MessageDataTypeVoice    = 34,
    MessageDataTypeVideo    = 43,
    MessageDataTypeSticker  = 47,
    MessageDataTypeLocation  = 48,
    MessageDataTypeAppUrl   = 49,
    MessageDataTypePrompt   = 10000
};

@interface NSString (MD5)

- (NSString *)md5String;

@end

@interface WeChat : NSObject

+ (instancetype)sharedInstance;
- (void)lock:(id)block;
- (void)showMainWindow;
- (void)startANewChatWithContact:(id)contact;

@end

@interface PathUtility : NSObject

+ (NSString *)GetCurUserDocumentPath;

@end

@interface MMSearchResultItem : NSObject

@property(nonatomic) unsigned long long type; // 0 is single chat, 1 is group chat
@property(readonly, nonatomic) NSString *identifier;

@end

@interface MessageData: NSObject

@property(nonatomic) MessageDataType messageType;
@property(nonatomic) unsigned int msgStatus;
@property(nonatomic) long long mesSvrID;
@property(retain, nonatomic) NSString *toUsrName;
@property(retain, nonatomic) NSString *fromUsrName;
@property(retain, nonatomic) NSString *msgContent;
@property(nonatomic) unsigned int msgCreateTime;
@property(nonatomic) unsigned int mesLocalID;

- (instancetype)initWithMsgType:(long long)arg1;
- (BOOL)isSendFromSelf;
- (id)getChatNameForCurMsg;
- (id)savingImageFileNameWithLocalID;

@end

@interface ReaderWrap : NSObject

@property(retain, nonatomic) NSString *m_nsTitle;
@property(retain, nonatomic) NSString *m_nsUrl;

@end

@interface WCContactData : NSObject

@property(nonatomic) unsigned int m_uiCertificationFlag;
@property(retain, nonatomic) NSString *m_nsHeadImgUrl;
@property(retain, nonatomic) NSString *m_nsNickName;
@property(retain, nonatomic) NSString *m_nsUsrName;
@property(retain, nonatomic) NSString *m_nsAliasName;
@property(retain, nonatomic) NSString *m_nsRemark;
@property(retain, nonatomic) NSString *m_nsFullPY;
@property(retain, nonatomic) NSString *m_nsRemarkPYShort;
@property(retain, nonatomic) NSString *m_nsRemarkPYFull;
@property(retain, nonatomic) NSString *wt_avatarPath;

- (BOOL)isChatStatusNotifyOpen;

@end

@interface ContactStorage : NSObject

- (WCContactData *)GetContact:(NSString *)session;
- (NSArray<WCContactData *> *)GetAllFriendContacts;

@end

@interface GroupStorage: NSObject

- (WCContactData *)GetGroupContact:(NSString *)session;
- (NSArray<WCContactData *> *)GetAllGroups;
- (NSArray<WCContactData *> *)GetGroupContactList:(NSInteger)arg1 ContactType:(NSInteger)arg2;

@end

@interface MMServiceCenter : NSObject

+ (id)defaultCenter;
- (id)getService:(Class)name;

@end

@interface MMAvatarService: NSObject

- (NSString *)avatarCachePath;

@end

@protocol MASPreferencesViewController <NSObject>

@property(readonly, nonatomic) NSString *toolbarItemLabel;
@property(readonly, nonatomic) NSImage *toolbarItemImage;
@property(readonly, nonatomic) NSString *identifier;

@optional
@property(readonly, nonatomic) BOOL hasResizableHeight;
@property(readonly, nonatomic) BOOL hasResizableWidth;

@end

@interface MASPreferencesWindowController: NSWindowController

- (id)initWithViewControllers:(NSArray *)arg1;

@end

@interface MMMessageTableItem : NSObject

@property(retain, nonatomic) MessageData *message;

@end

@interface MMMessageCellView : NSTableCellView

@property(retain, nonatomic) NSView *avatarImgView;
@property(retain, nonatomic) MMMessageTableItem *messageTableItem;

@end

@interface MMImageMessageCellView : MMMessageCellView

@property(retain, nonatomic) NSImage *displayedImage;

@end

@interface MMAppSingleReaderMessageCellView : MMMessageCellView

@property(retain, nonatomic) ReaderWrap *readerData;

@end

@interface MMAppMultipleReaderMessageCellView : MMMessageCellView

@property(retain, nonatomic) NSArray<ReaderWrap *> *readerMessages;
@property(assign, nonatomic) NSUInteger selectedReaderWrapIndex;

@end

@interface MMService : NSObject

@end

@interface EmoticonMgr : MMService

- (id)getEmotionDataWithMD5:(id)arg1;

@end

@interface FFProcessReqsvrZZ : NSObject

- (id)GetMsgData:(id)arg2 localId:(long long)arg3;
- (id)GetMsgData:(id)arg2 svrId:(long long)arg3;
- (void)AddLocalMsg:(id)arg2 msgData:(id)arg3;
- (void)ModifyMsgData:(id)arg2 msgData:(id)arg3;
- (void)notifyAddMsgOnMainThread:(id)arg2 msgData:(id)arg3;
- (void)notifyModMsgOnMainThread:(id)arg2 msgData:(id)arg3;
- (void)notifyDelMsgOnMainThread:(id)arg2 msgData:(id)arg3 isRevoke:(BOOL)arg4;
- (void)notifyUIAndSessionOnMainThread:(id)arg2 withMsg:(id)arg3;

@end

@interface NSDictionary (XMLDictionary)

+ (id)dictionaryWithXMLString:(id)arg1;

@end
