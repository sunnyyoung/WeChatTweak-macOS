//
//  MultipleInstances.m
//  WeChatTweak
//
//  Created by Sunny Young on 2022/2/1.
//  Copyright © 2022 Sunnyyoung. All rights reserved.
//

#import "WeChatTweak.h"
#import "NSBundle+WeChatTweak.h"

@implementation NSObject (MultipleInstances)

static void __attribute__((constructor)) tweak(void) {
    [objc_getClass("CUtility") jr_swizzleClassMethod:NSSelectorFromString(@"HasWechatInstance") withClassMethod:@selector(tweak_HasWechatInstance) error:nil];
    [objc_getClass("NSRunningApplication") jr_swizzleClassMethod:NSSelectorFromString(@"runningApplicationsWithBundleIdentifier:") withClassMethod:@selector(tweak_runningApplicationsWithBundleIdentifier:) error:nil];
    class_addMethod(objc_getClass("AppDelegate"), @selector(applicationDockMenu:), method_getImplementation(class_getInstanceMethod(objc_getClass("AppDelegate"), @selector(tweak_applicationDockMenu:))), "@:@");
}

+ (BOOL)tweak_HasWechatInstance {
    return NO;
}

+ (NSArray<NSRunningApplication *> *)tweak_runningApplicationsWithBundleIdentifier:(NSString *)bundleIdentifier {
    if ([bundleIdentifier isEqualToString:NSBundle.mainBundle.bundleIdentifier] ) {
        return @[NSRunningApplication.currentApplication];
    } else {
        return [self tweak_runningApplicationsWithBundleIdentifier:bundleIdentifier];
    }
}

- (NSMenu *)tweak_applicationDockMenu:(NSApplication *)sender {
    NSMenu *menu = [[NSMenu alloc] init];
    NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:[NSBundle.tweakBundle localizedStringForKey:@"Tweak.Title.LoginAnotherAccount"]
                                                      action:@selector(openNewWeChatInstace:)
                                               keyEquivalent:@""];
    [menu insertItem:menuItem atIndex:0];
    return menu;
}

- (void)openNewWeChatInstace:(id)sender {
    NSString *applicationPath = NSBundle.mainBundle.bundlePath;
    NSTask *task = [[NSTask alloc] init];
    task.launchPath = @"/usr/bin/open";
    task.arguments = @[@"-n", applicationPath];
    [task launch];
    [task waitUntilExit];
}

@end
