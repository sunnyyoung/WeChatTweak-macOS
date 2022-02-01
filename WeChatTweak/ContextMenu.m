//
//  ContextMenu.m
//  WeChatTweak
//
//  Created by Sunny Young on 2022/2/1.
//  Copyright © 2022 Sunnyyoung. All rights reserved.
//

#import "WeChatTweak.h"
#import "NSBundle+WeChatTweak.h"

#import <CoreImage/CoreImage.h>

@implementation NSObject (ContextMenu)

static void __attribute__((constructor)) tweak(void) {
    [objc_getClass("MMMessageCellView") jr_swizzleMethod:NSSelectorFromString(@"contextMenu") withMethod:@selector(tweak_contextMenu) error:nil];
}

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

@end
