//
//  InputHandler.h
//  WindowTools
//
//  Created by Grayson Chao on 11/5/13.
//  Copyright (c) 2013 Grayson Chao. All rights reserved.
//

#import <Foundation/Foundation.h>
@class AccessibilityWrapper;

CGEventRef catchClick(
    CGEventTapProxy proxy,
    CGEventType type,
    CGEventRef event,
    void *refcon
);

typedef NS_ENUM(BOOL, mouseClickType) {
    RIGHT,
    LEFT
};

// Key handling
id hotkeyMonitor;
id keyUpMonitor;
BOOL hotkeyOn;
NSInteger doublePressBuffer; // Used to detect hotkey double tap

// Mouse handling
id mouseMovedMonitor;
CFMachPortRef eventTap;
NSPoint mousePosition;
CGFloat mouseHorizontalDistanceFromTopLeft;
CGFloat mouseVerticalDistanceFromTopLeft;

BOOL enabled; // when NO, mouse events are passed through the EventTap without processing

// Window handling
AccessibilityWrapper *accessibilityWrapper;
BOOL hasWindow;

@interface InputHandler : NSObject

-(id)initWithMoveKey:(NSInteger)moveHotkey;
-(void)setDoublePressBuffer:(NSInteger)val;
-(NSInteger)getDoublePressBuffer;
-(void)resetDoublePressBuffer;

// Enable event tap and create it if needed
-(void)listenForMouseActivity;

-(void)mouseWasPressed;
-(void)mouseWasDragged:(BOOL)clickType;
-(void)mouseWasReleased;

@end
