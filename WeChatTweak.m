#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <objc/message.h>
#import <Cocoa/Cocoa.h>

// Tweak for no revoke message.
__attribute__((constructor(101))) static void noRevokeTweak(void) {
    Class class = NSClassFromString(@"MessageService");
    SEL selector = NSSelectorFromString(@"onRevokeMsg:");
    Method method = class_getInstanceMethod(class, selector);
    IMP imp = imp_implementationWithBlock(^(id self, NSString *message) {
        NSRange begin = [message rangeOfString:@"<replacemsg><![CDATA["];
        NSRange end = [message rangeOfString:@"]]></replacemsg>"];
        NSRange subRange = NSMakeRange(begin.location + begin.length,end.location - begin.location - begin.length);

        NSString *informativeText = [message substringWithRange:subRange];
        dispatch_async(dispatch_get_main_queue(), ^{
            NSUserNotification *userNotification = [[NSUserNotification alloc] init];
            userNotification.informativeText = informativeText;
            [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:userNotification];
        });
    });
    class_replaceMethod(class, selector, imp, method_getTypeEncoding(method));
}

// Tweak for multiple instance.
__attribute__((constructor(102))) static void multipleInstanceTweak(void) {
    Class class = object_getClass(NSClassFromString(@"CUtility"));
    SEL selector = NSSelectorFromString(@"HasWechatInstance");
    Method method = class_getInstanceMethod(class, selector);
    IMP imp = imp_implementationWithBlock(^(id self) {
        return 0;
    });
    class_replaceMethod(class, selector, imp, method_getTypeEncoding(method));
}
