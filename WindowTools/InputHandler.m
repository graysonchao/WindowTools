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
        if (moveHotkeyOn || resizeHotkeyOn) { // Steal the input if hotkey held
            [(__bridge InputHandler *)refcon mouseWasPressed];
            return NULL;
        }
        return event;
    } else if (isUp(e)) {
        mouseDown = NO;
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

+(id) createHotkeyMonitor {
    id eventMonitor = [NSEvent addGlobalMonitorForEventsMatchingMask:NSFlagsChangedMask handler:^(NSEvent *incomingEvent) {
        if ([incomingEvent keyCode] == 58) { // L or R alt
            NSUInteger state = [incomingEvent modifierFlags];
            switch (state) {
                case 0x80120: // L alt
                case 0x80140: // R alt
                    moveHotkeyOn = YES;
                    break;
                case 0x100: // KeyUp
                    moveHotkeyOn = NO;
            }
        } else if ([incomingEvent keyCode] == 59) {// Ctrl
            NSUInteger state = [incomingEvent modifierFlags];
            switch (state) {
                case 0x40101: // L ctrl on my macbook pro, sorry people with real keyboards
                    resizeHotkeyOn = YES;
                    break;
                case 0x100:
                    resizeHotkeyOn = NO;
            }
        }
    }];
    return eventMonitor;
}

-(void)mouseWasPressed {
    
    mousePosition = [NSEvent mouseLocation];
    //Normalize this position to the screen height (AccessibilityWrapper uses backwards coord system)
    mousePosition.y = [[NSScreen mainScreen] frame].size.height - mousePosition.y;
    
    AXUIElementRef targetWindow = [AccessibilityWrapper windowUnderPoint:mousePosition];
    if (targetWindow) {
        
        hasWindow = YES;
        
        AXUIElementRef targetApplication = [AccessibilityWrapper applicationForElement:targetWindow];
        
        accessibilityWrapper = [[AccessibilityWrapper alloc] initWithApp:targetApplication window:targetWindow];
       
        // We want to keep the mouse at a constant distance from the top left corner of the window.
        NSPoint windowTopLeft = [accessibilityWrapper getCurrentTopLeft];
//        NSLog(@"Window location: %f, %f", windowTopLeft.x, windowTopLeft.y);
        mouseHorizontalDistanceFromTopLeft = mousePosition.x - windowTopLeft.x;
        mouseVerticalDistanceFromTopLeft = mousePosition.y - windowTopLeft.y;
//        NSLog(@"Offset: %f, %f", mouseHorizontalDistanceFromTopLeft, mouseVerticalDistanceFromTopLeft);
    //  NSSize windowSize = [AccessibilityWrapper getSizeForWindow:targetWindow];
    } else {
        hasWindow = NO;
    }
   
   
}

-(void)mouseWasDragged {
    // Note to self: Y increases down. X increases right.
    if (hasWindow) {
        if (moveHotkeyOn) {
    //        NSLog(@"Mouse was moved");
    //        NSLog(@"hotkey %d, mousedown %d", hotkeyOn, mouseDown);
            NSPoint currentMousePosition = [NSEvent mouseLocation];
          
            // Again normalize the mouse position to the screen, because backwards coordinates.
            currentMousePosition.y = [[NSScreen mainScreen] frame].size.height - currentMousePosition.y;
            
            NSPoint windowDestination = [accessibilityWrapper getCurrentTopLeft];
            windowDestination = currentMousePosition;
            
            windowDestination.x -= mouseHorizontalDistanceFromTopLeft;
            windowDestination.y -= mouseVerticalDistanceFromTopLeft;
            
            [accessibilityWrapper moveWindow: windowDestination];
        } else if (resizeHotkeyOn) {
            NSPoint currentMousePosition = [NSEvent mouseLocation];
          
            // Again normalize the mouse position to the screen, because backwards coordinates.
            currentMousePosition.y = [[NSScreen mainScreen] frame].size.height - currentMousePosition.y;
            
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
