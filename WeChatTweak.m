#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <objc/message.h>
#import <Cocoa/Cocoa.h>

__attribute__((constructor))
static void initializer(void) {
    Class MessageServiceClass = NSClassFromString(@"MessageService");
    SEL onRevokeMsgSEL = NSSelectorFromString(@"onRevokeMsg:");
    IMP onRevokeMsgIMP = imp_implementationWithBlock(^(id self, id arg) {
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
    Method onRevokeMsgMethod = class_getInstanceMethod(MessageServiceClass, onRevokeMsgSEL);
    class_replaceMethod(MessageServiceClass, onRevokeMsgSEL, onRevokeMsgIMP, method_getTypeEncoding(onRevokeMsgMethod));
}
