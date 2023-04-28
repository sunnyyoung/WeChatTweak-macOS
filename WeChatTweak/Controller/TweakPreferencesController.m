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
    [self.notificationTypeButton selectItemAtIndex:[NSUserDefaults.standardUserDefaults integerForKey:WeChatTweakPreferenceRevokeNotificationTypeKey]];
}

#pragma mark - Event method

- (IBAction)switchNotificationTypeAction:(NSPopUpButton *)sender {
    [NSUserDefaults.standardUserDefaults setInteger:sender.indexOfSelectedItem forKey:WeChatTweakPreferenceRevokeNotificationTypeKey];
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
