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
    RIGHT_MOUSE,
    LEFT_MOUSE
};

typedef NS_ENUM(NSUInteger, windowArea) { // The areas of a window you could be clickin' upon
    WINDOW_TOP = 0,
    WINDOW_RIGHT = 1,
    WINDOW_BOTTOM = 2,
    WINDOW_LEFT = 3,
    WINDOW_ERROR = 4
};

NSStatusItem *menu;

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
NSUInteger mouseSideInWindow;

BOOL enabled; // when NO, mouse events are passed through the EventTap without processing

// Window handling
AccessibilityWrapper *accessibilityWrapper;
BOOL hasWindow;
NSSize windowSize;
NSPoint windowPosition;
BOOL snapResize; // Resize as part of moving

@interface InputHandler : NSObject

-(id)initWithMoveKey:(NSInteger)moveHotkey withMenu:(NSStatusItem *) menu;
-(void)setDoublePressBuffer:(NSInteger)val;
-(NSInteger)getDoublePressBuffer;
-(void)resetDoublePressBuffer; // to 0.

// Enable event tap and create it if needed
-(void)listenForMouseActivity;

-(void)mouseWasPressed;
-(void)mouseWasDragged:(BOOL)clickType;
-(void)mouseWasReleased;

@end
