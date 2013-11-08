//
//  InputHandler.h
//  WindowTools
//
//  Created by Grayson Chao on 11/5/13.
//  Copyright (c) 2013 Grayson Chao. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AccessibilityWrapper.h"

CGEventRef catchClick(
    CGEventTapProxy proxy,
    CGEventType type,
    CGEventRef event,
    void *refcon
);

CFMachPortRef eventTap;
NSPoint mousePosition;
CGFloat mouseHorizontalDistanceFromTopLeft;
CGFloat mouseVerticalDistanceFromTopLeft;
id mouseMovedMonitor;
BOOL moveHotkeyOn;
BOOL resizeHotkeyOn;
BOOL hasWindow;
BOOL mouseIsDown;

AccessibilityWrapper *accessibilityWrapper;

@interface InputHandler : NSObject

+(id)createHotkeyMonitor;
-(void)mouseWasPressed;
-(void)mouseWasDragged;
-(void)mouseWasReleased;
// Enable event tap and create it if needed
-(void)listenForMouseActivity;

@end
