#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <objc/message.h>
#import <Cocoa/Cocoa.h>
#import "JRSwizzle.h"

@implementation NSObject (WeChatTweak)

#pragma mark - Constructor

static void __attribute__((constructor)) tweak(void) {
    [objc_getClass("MessageService") jr_swizzleMethod:NSSelectorFromString(@"onRevokeMsg:") withMethod:@selector(tweak_onRevokeMsg:) error:nil];
    [objc_getClass("CUtility") jr_swizzleClassMethod:NSSelectorFromString(@"HasWechatInstance") withClassMethod:@selector(tweak_HasWechatInstance) error:nil];
    class_addMethod(objc_getClass("AppDelegate"), @selector(applicationDockMenu:), method_getImplementation(class_getInstanceMethod(objc_getClass("AppDelegate"), @selector(tweak_applicationDockMenu:))), "@:@");    
    [objc_getClass("AppDelegate") jr_swizzleMethod:NSSelectorFromString(@"applicationDidFinishLaunching:") withMethod:@selector(tweak_applicationDidFinishLaunching:) error:nil];
    [objc_getClass("AppDelegate") jr_swizzleMethod:NSSelectorFromString(@"applicationShouldTerminate:") withMethod:@selector(tweak_applicationShouldTerminate:) error:nil];
}

#pragma mark - No Revoke Message

- (void)tweak_onRevokeMsg:(NSString *)message {
    NSRange begin = [message rangeOfString:@"<replacemsg><![CDATA["];
    NSRange end = [message rangeOfString:@"]]></replacemsg>"];
    NSRange subRange = NSMakeRange(begin.location + begin.length,end.location - begin.location - begin.length);
    NSString *informativeText = [message substringWithRange:subRange];
    dispatch_async(dispatch_get_main_queue(), ^{
        NSUserNotification *userNotification = [[NSUserNotification alloc] init];
        userNotification.informativeText = informativeText;
        [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:userNotification];
    });
}

#pragma mark - Mutiple Instance

+ (BOOL)tweak_HasWechatInstance {
    return NO;
}

- (NSMenu *)tweak_applicationDockMenu:(NSApplication *)sender {
    NSMenu *menu = [[objc_getClass("NSMenu") alloc] init];
    NSMenuItem *menuItem = [[objc_getClass("NSMenuItem") alloc] initWithTitle:@"登录新的微信账号" action:@selector(openNewWeChatInstace:) keyEquivalent:@""];
    [menu insertItem:menuItem atIndex:0];
    return menu;
}

- (void)openNewWeChatInstace:(id)sender {
    NSString *applicationPath = [[objc_getClass("NSBundle") mainBundle] bundlePath];
    NSTask *task = [[objc_getClass("NSTask") alloc] init];
    task.launchPath = @"/usr/bin/open";
    task.arguments = @[@"-n", applicationPath];
    [task launch];
}

#pragma mark - No Logout

- (void)tweak_applicationDidFinishLaunching:(NSNotification *)notification {
    [self tweak_applicationDidFinishLaunching:notification];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wobjc-method-access"
    id serviceCenter = [objc_getClass("MMServiceCenter") defaultCenter];
    id accountService = [serviceCenter getService:objc_getClass("AccountService")];
    if ([accountService canAutoAuth]) {
        [accountService AutoAuth];
    }
#pragma clang diagnostic pop
}

- (NSApplicationTerminateReply)tweak_applicationShouldTerminate:(NSApplication *)sender {
    return NSTerminateNow;
}

@end
