//
//  WeChatTweak.m
//  WeChatTweak
//
//  Created by Sunnyyoung on 2017/8/11.
//  Copyright © 2017年 Sunnyyoung. All rights reserved.
//

#import "WeChatTweak.h"
#import "WeChatTweakHeaders.h"
#import "fishhook.h"
#import "NSBundle+WeChatTweak.h"
#import "NSString+WeChatTweak.h"
#import "TweakPreferencesController.h"
#import "AlfredManager.h"
#import "WTConfigManager.h"

// Global Function
static NSString *(*original_NSHomeDirectory)(void);
static NSArray<NSString *> *(*original_NSSearchPathForDirectoriesInDomains)(NSSearchPathDirectory directory, NSSearchPathDomainMask domainMask, BOOL expandTilde);
NSString *tweak_NSHomeDirectory(void) {
    return [original_NSHomeDirectory() stringByAppendingPathComponent:@"/Library/Containers/com.tencent.xinWeChat/Data/"];
}
NSArray<NSString *> *tweak_NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory directory, NSSearchPathDomainMask domainMask, BOOL expandTilde) {
    if (domainMask == NSUserDomainMask) {
        NSMutableArray<NSString *> *directories = [original_NSSearchPathForDirectoriesInDomains(directory, domainMask, expandTilde) mutableCopy];
        [directories enumerateObjectsUsingBlock:^(NSString * _Nonnull object, NSUInteger index, BOOL * _Nonnull stop) {
            switch (directory) {
                case NSDocumentDirectory: directories[index] = [tweak_NSHomeDirectory() stringByAppendingPathComponent:@"Documents"]; break;
                case NSLibraryDirectory: directories[index] = [tweak_NSHomeDirectory() stringByAppendingPathComponent:@"Library"]; break;
                case NSApplicationSupportDirectory: directories[index] = [tweak_NSHomeDirectory() stringByAppendingPathComponent:@"Library/Application Support"]; break;
                case NSCachesDirectory: directories[index] = [tweak_NSHomeDirectory() stringByAppendingPathComponent:@"Library/Caches"]; break;
                default: break;
            }
        }];
        return directories;
    } else {
        return original_NSSearchPathForDirectoriesInDomains(directory, domainMask, expandTilde);
    }
}

@implementation NSObject (WeChatTweak)

#pragma mark - Constructor

static void __attribute__((constructor)) tweak(void) {
    // Global Function Hook
    rebind_symbols((struct rebinding[2]) {
        { "NSHomeDirectory", tweak_NSHomeDirectory, (void *)&original_NSHomeDirectory },
        { "NSSearchPathForDirectoriesInDomains", tweak_NSSearchPathForDirectoriesInDomains, (void *)&original_NSSearchPathForDirectoriesInDomains }
    }, 2);
    // Method Swizzling
    class_addMethod(objc_getClass("AppDelegate"), @selector(applicationDockMenu:), method_getImplementation(class_getInstanceMethod(objc_getClass("AppDelegate"), @selector(tweak_applicationDockMenu:))), "@:@");
    [objc_getClass("AppDelegate") jr_swizzleMethod:NSSelectorFromString(@"applicationDidFinishLaunching:") withMethod:@selector(tweak_applicationDidFinishLaunching:) error:nil];
    [objc_getClass("CUtility") jr_swizzleClassMethod:NSSelectorFromString(@"HasWechatInstance") withClassMethod:@selector(tweak_HasWechatInstance) error:nil];
    [objc_getClass("NSRunningApplication") jr_swizzleClassMethod:NSSelectorFromString(@"runningApplicationsWithBundleIdentifier:") withClassMethod:@selector(tweak_runningApplicationsWithBundleIdentifier:) error:nil];
    [objc_getClass("MASPreferencesWindowController") jr_swizzleMethod:NSSelectorFromString(@"initWithViewControllers:") withMethod:@selector(tweak_initWithViewControllers:) error:nil];
    
    [objc_getClass("MMMessageCellView") jr_swizzleMethod:NSSelectorFromString(@"contextMenu") withMethod:@selector(tweak_contextMenu) error:nil];

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

#pragma mark - AppUrlMessageMenu

- (id)tweak_contextMenu {
    NSMenu *menu = (NSMenu *)[self tweak_contextMenu];
    if ([self isKindOfClass:objc_getClass("MMMessageCellView")]) {
        switch (((MMMessageCellView *)self).messageTableItem.message.messageType) {
            case MessageDataTypeAppUrl: {
                ReaderWrap *wrap = ({
                    ReaderWrap *wrap = nil;
                    if ([self isKindOfClass:objc_getClass("MMAppSingleReaderMessageCellView")]) {
                        MMAppSingleReaderMessageCellView *cell = (MMAppSingleReaderMessageCellView *)self;
                        wrap = cell.readerData;
                    } else if ([self isKindOfClass:objc_getClass("MMAppMultipleReaderMessageCellView")]) {
                        MMAppMultipleReaderMessageCellView *cell = (MMAppMultipleReaderMessageCellView *)self;
                        wrap = (cell.selectedReaderWrapIndex < cell.readerMessages.count) ? cell.readerMessages[cell.selectedReaderWrapIndex] : nil;
                    } else {
                        wrap = nil;
                    }
                    wrap;
                });
                if (wrap) {
                    [menu addItem:NSMenuItem.separatorItem];
                    [menu addItem:({
                        NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:[NSBundle.tweakBundle localizedStringForKey:@"Tweak.MessageMenuItem.CopyLink"]
                                                                      action:@selector(tweakCopyLink:)
                                                               keyEquivalent:@"c"];
                        item.target = wrap;
                        item;
                    })];
                    [menu addItem:({
                        NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:[NSBundle.tweakBundle localizedStringForKey:@"Tweak.MessageMenuItem.OpenInBrowser"]
                                                                             action:@selector(tweakOpenLink:)
                                                                      keyEquivalent:@"o"];
                        item.target = wrap;
                        item;
                    })];
                }
                break;
            }
            case MessageDataTypeImage: {
                [menu addItem:NSMenuItem.separatorItem];
                [menu addItem:({
                    NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:[NSBundle.tweakBundle localizedStringForKey:@"Tweak.MessageMenuItem.IdentifyQRCode"]
                                                                  action:@selector(tweakIdentifyQRCode:)
                                                           keyEquivalent:@"i"];
                    item.target = self;
                    item;
                })];
                break;
            }
            case MessageDataTypeSticker: {
                [menu addItem:NSMenuItem.separatorItem];
                [menu addItem:({
                    NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:[NSBundle.tweakBundle localizedStringForKey:@"Tweak.MessageMenuItem.ExportSticker"]
                                                                  action:@selector(tweakExportSticker:)
                                                           keyEquivalent:@"e"];
                    item.target = self;
                    item;
                })];
                break;
            }
            default: {
                break;
            }
        }
    }
    return menu;
}

- (void)tweakCopyLink:(NSMenuItem *)sender {
    ReaderWrap *wrap = sender.target;
    if (!wrap) {
        return;
    }
    if (wrap.m_nsUrl) {
        [NSPasteboard.generalPasteboard clearContents];
        [NSPasteboard.generalPasteboard setString:wrap.m_nsUrl forType:NSStringPboardType];
    }
}

- (void)tweakOpenLink:(NSMenuItem *)sender {
    ReaderWrap *wrap = sender.target;
    if (!wrap) {
        return;
    }
    if (wrap.m_nsUrl && [NSURL URLWithString:wrap.m_nsUrl]) {
        [NSWorkspace.sharedWorkspace openURL:[NSURL URLWithString:wrap.m_nsUrl]];
    }
}

- (void)tweakIdentifyQRCode:(NSMenuItem *)sender {
    NSImage *image = ((MMImageMessageCellView *)self).displayedImage;
    if (image) {
        NSData *imageData = [image TIFFRepresentation];
        CIDetector *detector = [CIDetector detectorOfType:CIDetectorTypeQRCode context:nil options:@{CIDetectorAccuracy: CIDetectorAccuracyHigh}];
        NSArray *results = [detector featuresInImage:[CIImage imageWithData:imageData]];
        if (results.count) {
            CIQRCodeFeature *result = results.firstObject;
            NSString *content = result.messageString;
            if (content.length) {
                NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
                [pasteboard clearContents];
                [pasteboard setString:content forType:NSStringPboardType];
                [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:({
                    NSUserNotification *notification = [[NSUserNotification alloc] init];
                    notification.informativeText = [NSBundle.tweakBundle localizedStringForKey:@"Tweak.MessageMenuItem.IdentifyQRCodeNotification"];
                    notification;
                })];
            }
        }
    }
}

- (void)tweakExportSticker:(NSMenuItem *)sender {
    MMMessageCellView *cell = (MMMessageCellView *)sender.target;
    MessageData *messageData = cell.messageTableItem.message;
    NSString *localID = [messageData savingImageFileNameWithLocalID];
    NSString *md5 = [NSDictionary dictionaryWithXMLString:[messageData.msgContent componentsSeparatedByString:@"\n"].lastObject][@"emoji"][@"_md5"];
    if (!localID.length || !md5.length) {
        return;
    }
    NSSavePanel *panel = [NSSavePanel savePanel];
    [panel setNameFieldStringValue:localID];
    [panel setAllowsOtherFileTypes:YES];
    [panel setAllowedFileTypes:@[@"gif"]];
    [panel setExtensionHidden:NO];
    [panel setCanCreateDirectories:YES];
    [panel beginSheetModalForWindow:cell.window completionHandler:^(NSModalResponse result) {
        if (result == NSModalResponseOK) {
            NSString *path = panel.URL.path;
            MMServiceCenter *serviceCenter = [objc_getClass("MMServiceCenter") defaultCenter];
            EmoticonMgr *emoticonMgr = [serviceCenter getService:objc_getClass("EmoticonMgr")];
            NSData *stickerData = [emoticonMgr getEmotionDataWithMD5:md5];
            [stickerData writeToFile:path atomically:YES];
        }
    }];
}

#pragma mark - Mutiple Instance

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

#pragma mark - Alfred

- (void)tweak_applicationDidFinishLaunching:(NSNotification *)notification {
    [AlfredManager.sharedInstance startListener];
    [self tweak_applicationDidFinishLaunching:notification];
}

#pragma mark - Preferences Window

- (id)tweak_initWithViewControllers:(NSArray *)arg1 {
    NSMutableArray *viewControllers = [NSMutableArray arrayWithArray:arg1];
    TweakPreferencesController *controller = [[TweakPreferencesController alloc] initWithNibName:nil bundle:[NSBundle tweakBundle]];
    [viewControllers addObject:controller];
    return [self tweak_initWithViewControllers:viewControllers];
}

#pragma mark - WCContact Data

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
    return WTConfigManager.sharedInstance.compressedJSONEnabled ? list : nil;
}

@end
