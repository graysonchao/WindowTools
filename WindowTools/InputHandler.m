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

#define isClick(e) ([e type] == NSLeftMouseDown || [e type] == NSRightMouseDown)

#define isUp(e) ([e type] == NSLeftMouseUp || [e type] == NSRightMouseUp)

@implementation InputHandler

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
        mouseDown = YES;
        if (hotkeyOn) { // Steal the input if hotkey held
            [(__bridge InputHandler *)refcon mouseWasPressed];
            return NULL;
        }
        return event;
    } else if (isUp(e)) {
        mouseDown = NO;
        if (hotkeyOn) {
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
            NSLog(@"%@ no tap; universal access?", NSStringFromSelector(_cmd));
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

+(id) createHotkeyMonitor {
    // Watch for whenever the user presses alt
    id eventMonitor = [NSEvent addGlobalMonitorForEventsMatchingMask:NSFlagsChangedMask handler:^(NSEvent *incomingEvent) {
        if ([incomingEvent keyCode] == 58) { // L or R alt
            NSUInteger state = [incomingEvent modifierFlags];
            switch (state) {
                case 0x80120:
                    NSLog(@"Alt down yo");
                    hotkeyOn = YES;
                    break;
                case 0x100: // KeyUp
                    NSLog(@"Alt up yo!");
                    hotkeyOn = NO;
            }
        }
    }];
    return eventMonitor;
}

-(void)mouseWasPressed {
    
    mousePosition = [NSEvent mouseLocation];
    
    AXUIElementRef targetWindow = [AccessibilityWrapper windowUnderPoint:mousePosition];
    AXUIElementRef targetApplication = [AccessibilityWrapper applicationForElement:targetWindow];
    
    accessibilityWrapper = [[AccessibilityWrapper alloc] initWithApp:targetApplication window:targetWindow];
   
    // We want to keep the mouse equidistant from the top left corner of the window.
    NSPoint windowTopLeft = [accessibilityWrapper getCurrentTopLeft];
    mouseHorizontalDistanceFromTopLeft = mousePosition.x - windowTopLeft.x;
    mouseVerticalDistanceFromTopLeft = windowTopLeft.y - mousePosition.y;
//  NSSize windowSize = [AccessibilityWrapper getSizeForWindow:targetWindow];
   
   
}

-(void)mouseWasDragged {
    // Note to self: Y increases up. X increases right.
    if (hotkeyOn) {
        NSLog(@"Mouse was moved");
        NSLog(@"hotkey %d, mousedown %d", hotkeyOn, mouseDown);
        NSPoint mousePosition = [NSEvent mouseLocation];
        NSPoint windowDestination = mousePosition;
        
        windowDestination.y = [[NSScreen mainScreen] frame].size.height - windowDestination.y; // Normalize to screen
        
        windowDestination.x -= mouseHorizontalDistanceFromTopLeft;
        windowDestination.y -= mouseVerticalDistanceFromTopLeft;
        
//        float mouseDeltaX = (newMousePosition.x - mousePosition.x);
//        float mouseDeltaY = (newMousePosition.y - mousePosition.y);
//        
//        NSSize oldWindowSize = [accessibilityWrapper getCurrentSize];
//        NSSize newSize = oldWindowSize;
//        newSize.width = newSize.width + mouseDeltaX;
//        newSize.height = newSize.height - mouseDeltaY;
        [accessibilityWrapper moveWindow: windowDestination];
    }
}

-(void)mouseWasReleased {
    accessibilityWrapper = NULL;
    NSLog(@"Mouse was released at %f, %f!",
          mousePosition.x, mousePosition.y);
}

@end
