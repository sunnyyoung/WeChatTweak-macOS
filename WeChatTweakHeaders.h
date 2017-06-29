#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>

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

@property(retain, nonatomic) NSString *m_nsNickName;

@end

@interface GroupStorage: NSObject

- (id)GetGroupContact:(id)arg1;

@end

@interface MMServiceCenter : NSObject

+ (id)defaultCenter;
- (id)getService:(Class)arg1;

@end

@interface MessageService: NSObject

- (id)GetMsgData:(id)arg1 svrId:(unsigned long long)arg2;
- (void)DelMsg:(id)arg1 msgList:(id)arg2 isDelAll:(BOOL)arg3 isManual:(BOOL)arg4;
- (void)AddRevokePromptMsg:(id)arg1 msgData:(id)arg2;
- (void)notifyAddMsgOnMainThread:(id)arg1 msgData:(id)arg2;

@end

@interface AccountService: NSObject

- (BOOL)canAutoAuth;
- (void)AutoAuth;

@end