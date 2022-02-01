//
//  TweakPreferencesController.m
//  WeChatTweak
//
//  Created by Sunnyyoung on 2017/8/12.
//  Copyright © 2017年 Sunnyyoung. All rights reserved.
//

#import "TweakPreferencesController.h"
#import "NSBundle+WeChatTweak.h"

@interface TweakPreferencesController () <MASPreferencesViewController>

@property (weak) IBOutlet NSPopUpButton *notificationTypeButton;
@property (weak) IBOutlet NSPopUpButton *compressedJSONEnabledButton;
@property (weak) IBOutlet NSPopUpButton *revokedMessageStyleButton;

@end

@implementation TweakPreferencesController

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)viewWillAppear {
    [super viewWillAppear];
    [self reloadData];
}

- (void)reloadData {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    RevokeNotificationType notificationType = [userDefaults integerForKey:WeChatTweakPreferenceRevokeNotificationTypeKey];
    [self.notificationTypeButton selectItemAtIndex:notificationType];
    [self.compressedJSONEnabledButton selectItemAtIndex:WeChatTweak.compressedJSONEnabled ? 0 : 1];
    [self.revokedMessageStyleButton selectItemAtIndex:WeChatTweak.revokedMessageStyle];
}

#pragma mark - Event method

- (IBAction)switchNotificationTypeAction:(NSPopUpButton *)sender {
    RevokeNotificationType type = sender.indexOfSelectedItem;
    [[NSUserDefaults standardUserDefaults] setInteger:type forKey:WeChatTweakPreferenceRevokeNotificationTypeKey];
}

- (IBAction)switchCompressedJSONEnabledAction:(NSPopUpButton *)sender {
    BOOL enabled = sender.indexOfSelectedItem == 0;
    WeChatTweak.compressedJSONEnabled = enabled;
}

- (IBAction)switchRevokedMessageStyleButton:(NSPopUpButton *)sender {
    WeChatTweak.revokedMessageStyle = sender.indexOfSelectedItem;
}

#pragma mark - MASPreferencesViewController

- (NSString *)identifier {
    return @"tweak";
}

- (NSString *)toolbarItemLabel {
    return @"Tweak";
}

- (NSImage *)toolbarItemImage {
    return [[NSBundle tweakBundle] imageForResource:@"Prefs-Tweak"];
}

- (BOOL)hasResizableWidth {
    return NO;
}

- (BOOL)hasResizableHeight {
    return NO;
}

@end
