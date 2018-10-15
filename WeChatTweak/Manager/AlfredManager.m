//
//  AlfredManager.m
//  WeChatTweak
//
//  Created by Sunnyyoung on 2017/9/10.
//  Copyright © 2017年 Sunnyyoung. All rights reserved.
//

#import "AlfredManager.h"
#import "WeChatTweakHeaders.h"

@interface AlfredManager()

@property (nonatomic, strong, nullable) GCDWebServer *server;

@end

@implementation AlfredManager

static int port = 48065;
    
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
    // Search contancts
    [self.server addHandlerForMethod:@"GET" path:@"/wechat/search" requestClass:[GCDWebServerRequest class] processBlock:^GCDWebServerResponse * _Nullable(__kindof GCDWebServerRequest * _Nonnull request) {
        NSString *keyword = [request.query[@"keyword"] lowercaseString] ? : @"";
        
        NSString *hostname = request.headers[@"Host"];
        NSString *url1 = [NSString stringWithFormat:@"127.0.0.1:%d", port];
        NSString *url2 = [NSString stringWithFormat:@"localhost:%d", port];
        if(!([hostname isEqualToString:url1] | [hostname isEqualToString:url2])){
            return [GCDWebServerResponse responseWithStatusCode:404];
        }
        
        NSArray<WCContactData *> *contacts = ({
            MMServiceCenter *serviceCenter = [objc_getClass("MMServiceCenter") defaultCenter];
            ContactStorage *contactStorage = [serviceCenter getService:objc_getClass("ContactStorage")];
            GroupStorage *groupStorage = [serviceCenter getService:objc_getClass("GroupStorage")];
            NSMutableArray<WCContactData *> *array = [NSMutableArray array];
            [array addObjectsFromArray:[contactStorage GetAllFriendContacts]];
            [array addObjectsFromArray:[groupStorage GetGroupContactList:2 ContactType:0]];
            array;
        });
        NSArray<WCContactData *> *results = ({
            NSMutableArray<WCContactData *> *results = [NSMutableArray array];
            for (WCContactData *contact in contacts) {
                BOOL isOfficialAccount = (contact.m_uiCertificationFlag >> 0x3 & 0x1) == 1;
                BOOL containsNickName = [contact.m_nsNickName.lowercaseString containsString:keyword];
                BOOL containsUsername = [contact.m_nsUsrName.lowercaseString containsString:keyword];
                BOOL containsAliasName = [contact.m_nsAliasName.lowercaseString containsString:keyword];
                BOOL containsRemark = [contact.m_nsRemark.lowercaseString containsString:keyword];
                BOOL containsNickNamePinyin = [contact.m_nsFullPY.lowercaseString containsString:keyword];
                BOOL containsRemarkPinyin = [contact.m_nsRemarkPYFull.lowercaseString containsString:keyword];
                BOOL matchRemarkShortPinyin = [contact.m_nsRemarkPYShort.lowercaseString isEqualToString:keyword];
                if (!isOfficialAccount && (containsNickName || containsUsername || containsAliasName || containsRemark || containsNickNamePinyin || containsRemarkPinyin || matchRemarkShortPinyin)) {
                    [results addObject:contact];
                }
            }
            results;
        });
        return [GCDWebServerDataResponse responseWithJSONObject:[results yy_modelToJSONObject]];
    }];
    // Start chat
    [self.server addHandlerForMethod:@"GET" path:@"/wechat/start" requestClass:[GCDWebServerRequest class] processBlock:^GCDWebServerResponse * _Nullable(__kindof GCDWebServerRequest * _Nonnull request) {
        
        NSString *hostname = request.headers[@"Host"];
        NSString *url1 = [NSString stringWithFormat:@"127.0.0.1:%d", port];
        NSString *url2 = [NSString stringWithFormat:@"localhost:%d", port];
        if(!([hostname isEqualToString:url1] | [hostname isEqualToString:url2])){
            return [GCDWebServerResponse responseWithStatusCode:404];
        }
        
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
    [self.server startWithOptions:@{GCDWebServerOption_Port: [NSNumber numberWithInt:port],
                                    GCDWebServerOption_BindToLocalhost: @(YES)} error:nil];
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
