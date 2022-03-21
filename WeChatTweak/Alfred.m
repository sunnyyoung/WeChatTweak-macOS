//
//  Alfred.m
//  WeChatTweak
//
//  Created by Sunnyyoung on 2017/9/10.
//  Copyright © 2017年 Sunnyyoung. All rights reserved.
//

#import "Alfred.h"
#import "WeChatTweak.h"

@interface AlfredManager()

@property (nonatomic, strong, nullable) GCDWebServer *server;

@end

@implementation AlfredManager

+ (void)load {
    [AlfredManager.sharedInstance startListener];
}
    
+ (instancetype)sharedInstance {
    static dispatch_once_t onceToken;
    static AlfredManager *shared;
    dispatch_once(&onceToken, ^{
        shared = [[AlfredManager alloc] init];
    });
    return shared;
}

- (void)startListener {
    if (self.server != nil) {
        return;
    }
    self.server = [[GCDWebServer alloc] init];
    // Search contacts
    [self.server addHandlerForMethod:@"GET" path:@"/wechat/search" requestClass:[GCDWebServerRequest class] processBlock:^GCDWebServerResponse * _Nullable(__kindof GCDWebServerRequest * _Nonnull request) {
        NSString *path = ({
            NSString *path = nil;
            if ([objc_getClass("PathUtility") respondsToSelector:@selector(GetCurUserDocumentPath)]) {
                path = [objc_getClass("PathUtility") GetCurUserDocumentPath];
            } else {
                path = nil;
            }
            path;
        });
        NSString *keyword = [request.query[@"keyword"] lowercaseString] ? : @"";
        
        NSArray<WCContactData *> *contacts = ({
            MMServiceCenter *serviceCenter = [objc_getClass("MMServiceCenter") defaultCenter];
            ContactStorage *contactStorage = [serviceCenter getService:objc_getClass("ContactStorage")];
            GroupStorage *groupStorage = [serviceCenter getService:objc_getClass("GroupStorage")];
            NSMutableArray<WCContactData *> *array = [NSMutableArray array];
            [array addObjectsFromArray:[contactStorage GetAllFriendContacts]];
            [array addObjectsFromArray:[groupStorage GetGroupContactList:2 ContactType:0]];
            array;
        });
        NSArray<NSDictionary<NSString *, id> *> *items = ({
            NSMutableArray<NSDictionary<NSString *, id> *> *items = NSMutableArray.array;
            for (WCContactData *contact in contacts) {
                NSString *avatar = [NSString stringWithFormat:@"%@/Avatar/%@.jpg", path, [contact.m_nsUsrName md5String]];
                BOOL isOfficialAccount = (contact.m_uiCertificationFlag >> 0x3 & 0x1) == 1;
                BOOL containsNickName = [contact.m_nsNickName.lowercaseString containsString:keyword];
                BOOL containsUsername = [contact.m_nsUsrName.lowercaseString containsString:keyword];
                BOOL containsAliasName = [contact.m_nsAliasName.lowercaseString containsString:keyword];
                BOOL containsRemark = [contact.m_nsRemark.lowercaseString containsString:keyword];
                BOOL containsNickNamePinyin = [contact.m_nsFullPY.lowercaseString containsString:keyword];
                BOOL containsRemarkPinyin = [contact.m_nsRemarkPYFull.lowercaseString containsString:keyword];
                BOOL matchRemarkShortPinyin = [contact.m_nsRemarkPYShort.lowercaseString isEqualToString:keyword];
                if (!isOfficialAccount && (containsNickName || containsUsername || containsAliasName || containsRemark || containsNickNamePinyin || containsRemarkPinyin || matchRemarkShortPinyin)) {
                    [items addObject:@{
                        @"icon": @{
                            @"path": [NSFileManager.defaultManager fileExistsAtPath:avatar] ? avatar : NSNull.null
                        },
                        @"title": ({
                            id value = nil;
                            if (contact.m_nsRemark.length) {
                                value = contact.m_nsRemark;
                            } else if (contact.m_nsNickName.length) {
                                value = contact.m_nsNickName;
                            } else {
                                value = NSNull.null;
                            }
                            value;
                        }),
                        @"subtitle": contact.m_nsNickName.length ? contact.m_nsNickName : NSNull.null,
                        @"arg": contact.m_nsUsrName.length ? contact.m_nsUsrName : NSNull.null,
                        @"valid": @(contact.m_nsUsrName.length > 0)
                    }];
                }
            }
            items;
        });
        return [GCDWebServerDataResponse responseWithJSONObject:@{@"items": items}];
    }];
    // Start session
    [self.server addHandlerForMethod:@"GET" path:@"/wechat/start" requestClass:[GCDWebServerRequest class] processBlock:^GCDWebServerResponse * _Nullable(__kindof GCDWebServerRequest * _Nonnull request) {
        WCContactData *contact = ({
            NSString *session = request.query[@"session"];
            WCContactData *contact = nil;
            if (session != nil) {
                MMServiceCenter *serviceCenter = [objc_getClass("MMServiceCenter") defaultCenter];
                if ([session rangeOfString:@"@chatroom"].location == NSNotFound) {
                    ContactStorage *contactStorage = [serviceCenter getService:objc_getClass("ContactStorage")];
                    contact = [contactStorage GetContact:session];
                } else {
                    GroupStorage *groupStorage = [serviceCenter getService:objc_getClass("GroupStorage")];
                    contact = [groupStorage GetGroupContact:session];
                }
            }
            contact;
        });
        dispatch_async(dispatch_get_main_queue(), ^{
            [[objc_getClass("WeChat") sharedInstance] startANewChatWithContact:contact];
            [[objc_getClass("WeChat") sharedInstance] showMainWindow];
            [[NSApplication sharedApplication] activateIgnoringOtherApps: YES];
        });
        return [GCDWebServerResponse responseWithStatusCode:200];
    }];
    [self.server startWithOptions:@{
        GCDWebServerOption_Port: @(48065),
        GCDWebServerOption_BindToLocalhost: @(YES)
    } error:nil];
}

- (void)stopListener {
    if (self.server == nil) {
        return;
    }
    [self.server stop];
    [self.server removeAllHandlers];
    self.server = nil;
}

@end
