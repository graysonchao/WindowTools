//
//  InputHandler.m
//  WindowTools
//
//  Created by Grayson Chao on 11/5/13.
//  Copyright (c) 2013 Grayson Chao. All rights reserved.
//

#import "InputHandler.h"
#import "AccessibilityWrapper.h"
#import "NSScreen+PointConversion.h"
#import <Carbon/Carbon.h> // for keycodes

#define isClick(e) ([e type] == NSLeftMouseDown || [e type] == NSRightMouseDown)
#define isUp(e) ([e type] == NSLeftMouseUp || [e type] == NSRightMouseUp)

@implementation InputHandler

-(id) initWithMoveKey:(NSInteger)moveHotkey resizeKey:(NSInteger)resizeHotkey {
    if ( self = [super init] ) {
        hotkeyMonitor = [NSEvent addGlobalMonitorForEventsMatchingMask:NSFlagsChangedMask handler:^(NSEvent *incomingEvent) {
            NSLog(@"%@", [incomingEvent description]);
            if ([incomingEvent keyCode] & moveHotkey) {
                NSUInteger state = [incomingEvent modifierFlags];
                if (state & NSCommandKeyMask) {
                    moveHotkeyOn = YES;
                } else {
                    moveHotkeyOn = NO;
                }
            } else if ([incomingEvent keyCode] & resizeHotkey) {
                NSUInteger state = [incomingEvent modifierFlags];
                if (state & NSControlKeyMask) {
                    resizeHotkeyOn = YES;
                } else {
                    resizeHotkeyOn = NO;
                }
            }
        }];
        keyUpMonitor = [NSEvent addGlobalMonitorForEventsMatchingMask:NSKeyUpMask handler:^(NSEvent *incomingEvent) {
            moveHotkeyOn = NO;
            resizeHotkeyOn = NO;
        }];
        [self listenForMouseActivity];
        return self;
    } else {
        return nil;
    }
}
// Thanks to Nolan Waite for directing me toward Kevin Gessner's post
// in https://github.com/nolanw/Ejectulate/blob/master/src/EJEjectKeyWatcher.m
// Original post:
// http://www.cocoabuilder.com/archive/cocoa/222356-play-pause-rew-ff-keys.html

static CGEventRef mouseDownCallback(CGEventTapProxy proxy,
                                  CGEventType type,
                                  CGEventRef event,
                                  void *refcon) {
    // For whatever reason the system seems to disable the event tap after a few
    // minutes without being used (or maybe after being enabled, not sure). If
    // that happens, just reenable it and all's well.
    if (type == kCGEventTapDisabledByTimeout)
    {
        [(__bridge InputHandler *)refcon  listenForMouseActivity];
        return NULL;
    }
    NSEvent *e = [NSEvent eventWithCGEvent:event];
    if (isClick(e)) {
        mouseIsDown = YES;
        if (moveHotkeyOn || resizeHotkeyOn) { // Steal the input if hotkey held
            [(__bridge InputHandler *)refcon mouseWasPressed];
            return NULL;
        }
        return event;
    } else if (isUp(e)) {
        mouseIsDown = NO;
        if (moveHotkeyOn) {
            [(__bridge InputHandler *)refcon mouseWasReleased];
        }
    }
    return event;
}

- (void)listenForMouseActivity {
    CGEventMask mask = CGEventMaskBit(kCGEventLeftMouseDown) | CGEventMaskBit(kCGEventRightMouseDown) | CGEventMaskBit(kCGEventLeftMouseUp) | CGEventMaskBit(kCGEventRightMouseUp);
    
    if (!eventTap) {
        
        eventTap = CGEventTapCreate(kCGSessionEventTap, kCGHeadInsertEventTap, 0,
                                    mask, mouseDownCallback, (__bridge void *)(self));
        if (!eventTap) {
//            NSLog(@"%@ no tap; universal access?", NSStringFromSelector(_cmd));
            return;
        }
        CFRunLoopSourceRef runLoopSource = CFMachPortCreateRunLoopSource(NULL,
                                                                         eventTap, 0);
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource,
                           kCFRunLoopCommonModes);
        CFRelease(runLoopSource);
    }
    CGEventTapEnable(eventTap, true);
    
    mouseMovedMonitor = [NSEvent addGlobalMonitorForEventsMatchingMask:NSLeftMouseDraggedMask|NSRightMouseDraggedMask handler:^(NSEvent * event) {
        [self mouseWasDragged];
    }];
    
}

/* TODO: Parameterize keyCode/event flag checks */

-(void)mouseWasPressed {
    
    mousePosition = [NSEvent mouseLocation];
    mousePosition = [[NSScreen mainScreen] flipPoint:mousePosition];
    
    AXUIElementRef targetWindow = [AccessibilityWrapper windowUnderPoint:mousePosition];
    if (targetWindow) {
        
        hasWindow = YES;
        
        AXUIElementRef targetApplication = [AccessibilityWrapper applicationForElement:targetWindow];
        
        accessibilityWrapper = [[AccessibilityWrapper alloc] initWithApp:targetApplication window:targetWindow];
       
        // We want to keep the mouse at a constant distance from the top left corner of the window.
        NSPoint windowTopLeft = [accessibilityWrapper getCurrentTopLeft];
        
        mouseHorizontalDistanceFromTopLeft = mousePosition.x - windowTopLeft.x;
        mouseVerticalDistanceFromTopLeft = mousePosition.y - windowTopLeft.y;
    } else {
        hasWindow = NO;
    }
}

-(void)mouseWasDragged {
    if (hasWindow) {
        if (moveHotkeyOn) {
            NSPoint currentMousePosition = [NSEvent mouseLocation];
            currentMousePosition = [[NSScreen mainScreen] flipPoint:currentMousePosition];

            NSPoint windowTopLeft = [accessibilityWrapper getCurrentTopLeft];
            NSPoint windowDestination = windowTopLeft;
            windowDestination = currentMousePosition;
           
            windowDestination.x -= mouseHorizontalDistanceFromTopLeft;
            windowDestination.y -= mouseVerticalDistanceFromTopLeft;

            // Snap to left edge
            if (fabs(windowDestination.x) < 10)
                windowDestination.x = 0;
           
            CGFloat screenRightEdge = [[NSScreen mainScreen] frame].size.width;
            NSSize windowSize = [accessibilityWrapper getCurrentSize];
            CGFloat windowRightEdge = windowDestination.x + windowSize.width;
          
            NSLog(@"%f", fabs(screenRightEdge - windowRightEdge));
            // Snap to right edge
            if (fabs(screenRightEdge - windowRightEdge) < 10) {
                windowDestination.x = screenRightEdge - windowSize.width;
            }
            
            [accessibilityWrapper moveWindow: windowDestination];
        } else if (resizeHotkeyOn) {
            NSPoint currentMousePosition = [NSEvent mouseLocation];
            currentMousePosition = [[NSScreen mainScreen] flipPoint:currentMousePosition];
            
            float mouseDeltaX = (currentMousePosition.x - mousePosition.x);
            float mouseDeltaY = (currentMousePosition.y - mousePosition.y);
    
            NSSize oldWindowSize = [accessibilityWrapper getCurrentSize];
            NSSize newSize = oldWindowSize;
            newSize.width += mouseDeltaX;
            newSize.height += mouseDeltaY;
            
            [accessibilityWrapper resizeWindow: newSize];
            
            mousePosition = currentMousePosition;
        }
    }
}

-(void)mouseWasReleased {
//    NSLog(@"Mouse was released at %f, %f!",
//          mousePosition.x, mousePosition.y);
}

@end
