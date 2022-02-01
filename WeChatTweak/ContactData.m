//
//  ContactData.m
//  WeChatTweak
//
//  Created by Sunny Young on 2022/2/1.
//  Copyright © 2022 Sunnyyoung. All rights reserved.
//

#import "WeChatTweak.h"

@implementation NSObject (ContactData)

static void __attribute__((constructor)) tweak(void) {
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
    NSArray *list =@[
        @"wt_avatarPath",
        @"m_nsRemark",
        @"m_nsNickName",
        @"m_nsUsrName"
    ];
    return WeChatTweak.compressedJSONEnabled ? list : nil;
}

@end
