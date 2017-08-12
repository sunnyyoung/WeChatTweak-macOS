//
//  TweakPreferecesController.m
//  WeChatTweak
//
//  Created by Sunnyyoung on 2017/8/12.
//  Copyright © 2017年 Sunnyyoung. All rights reserved.
//

#import "TweakPreferecesController.h"
#import "NSBundle+WeChatTweak.h"

@interface TweakPreferecesController () <MASPreferencesViewController>

@property (weak) IBOutlet NSPopUpButton *autoAuthButton;
@property (weak) IBOutlet NSPopUpButton *notificationTypeButton;

@end

@implementation TweakPreferecesController

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)viewWillAppear {
    [super viewWillAppear];
    [self reloadData];
}

- (void)reloadData {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    BOOL enabledAutoAuth = [userDefaults boolForKey:WeChatTweakPreferenceAutoAuthKey];
    RevokeNotificationType notificationType = [userDefaults integerForKey:WeChatTweakPreferenceRevokeNotificationTypeKey];
    [self.autoAuthButton selectItemAtIndex:enabledAutoAuth ? 1 : 0];
    [self.notificationTypeButton selectItemAtIndex:notificationType];
}

#pragma mark - Event method

- (IBAction)switchAutoAuthAction:(NSPopUpButton *)sender {
    BOOL enabled = sender.indexOfSelectedItem == 1;
    [[NSUserDefaults standardUserDefaults] setBool:enabled forKey:WeChatTweakPreferenceAutoAuthKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (IBAction)switchNotificationTypeAction:(NSPopUpButton *)sender {
    RevokeNotificationType type = sender.indexOfSelectedItem;
    [[NSUserDefaults standardUserDefaults] setInteger:type forKey:WeChatTweakPreferenceRevokeNotificationTypeKey];
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
