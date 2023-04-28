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
@property (weak) IBOutlet NSColorWell *maskColorWell;

@end

@implementation TweakPreferencesController

- (void)viewDidLoad {
    [super viewDidLoad];
    [NSColorPanel.sharedColorPanel setShowsAlpha:YES];
}

- (void)viewWillAppear {
    [super viewWillAppear];
    [self reloadData];
}

- (void)reloadData {
    self.maskColorWell.color = WeChatTweak.maskColor;
    [self.notificationTypeButton selectItemAtIndex:WeChatTweak.notificationType];
}

#pragma mark - Event method

- (IBAction)switchNotificationTypeAction:(NSPopUpButton *)sender {
    WeChatTweak.notificationType = sender.indexOfSelectedItem;
}

- (IBAction)changeMaskColorAction:(NSColorWell *)sender {
    WeChatTweak.maskColor = sender.color;
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
