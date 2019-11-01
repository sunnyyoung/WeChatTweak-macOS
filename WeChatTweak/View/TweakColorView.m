//
//  TweakColorView.m
//  WeChatTweak
//
//  Created by Jeason Lee on 2019/11/1.
//  Copyright © 2019 Sunnyyoung. All rights reserved.
//

#import "TweakColorView.h"

@implementation TweakColorView

- (void)mouseDown:(NSEvent *)event {
    [NSColorPanel dragColor:self.backgroundColor withEvent:event fromView:self];
}

- (void)setBackgroundColor:(NSColor *)backgroundColor {
    _backgroundColor = backgroundColor;
    dispatch_async(dispatch_get_main_queue(), ^{
        self.layer.backgroundColor = backgroundColor.CGColor;
    });
}

@end
