#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <objc/message.h>
#import <Cocoa/Cocoa.h>

__attribute__((constructor))
static void initializer(void) {
    Class messageServiceClass = NSClassFromString(@"MessageService");
    SEL onRevokeMsgSEL = NSSelectorFromString(@"onRevokeMsg:");
    IMP hookIMP = imp_implementationWithBlock(^(id self, id arg) {
        NSString *message = (NSString *)arg;
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
    Method originMethod = class_getInstanceMethod(messageServiceClass, onRevokeMsgSEL);
    IMP originImp = class_replaceMethod(messageServiceClass, onRevokeMsgSEL, hookIMP, method_getTypeEncoding(originMethod));
}
