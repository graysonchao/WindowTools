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

#define isLeftClick(e) ([e type] == NSLeftMouseDown)
#define isLeftDrag(e) ([e type] == NSLeftMouseDragged)
#define isRightClick(e) ([e type] == NSRightMouseDown)
#define isRightDrag(e) ([e type] == NSRightMouseDragged)
#define isUp(e) ([e type] == NSLeftMouseUp || [e type] == NSRightMouseUp)

@implementation InputHandler

-(id) initWithMoveKey:(NSInteger)moveHotkey withMenu:(NSStatusItem *) theMenu{
    if ( self = [super init] ) {
        enabled = YES;
        menu = theMenu;
        hotkeyMonitor = [NSEvent addGlobalMonitorForEventsMatchingMask:NSFlagsChangedMask handler:^(NSEvent *incomingEvent) {
            //NSLog(@"%@", [incomingEvent description]);
            if ([incomingEvent keyCode] & moveHotkey) {
                NSUInteger state = [incomingEvent modifierFlags] & NSDeviceIndependentModifierFlagsMask;
                if (state == NSCommandKeyMask) {
                    switch ([self getDoublePressBuffer]) {
                        case 0:
                            [self setDoublePressBuffer:1];
                            [NSTimer scheduledTimerWithTimeInterval: 0.3
                                                             target: self
                                                           selector: @selector(resetDoublePressBuffer)
                                                           userInfo: nil
                                                            repeats: NO];
                            break;
                        case 1:
                            enabled = !enabled;
                            if (enabled) {
                                [menu setTitle:@"W"];
                            } else {
                                [menu setTitle:@"X"];
                            }
                            NSLog(@"Enabled: %d", enabled);
                            [self setDoublePressBuffer:0];
                            break;
                        default:
                            [self resetDoublePressBuffer];
                            break;
                    }
                }
                if (state & NSCommandKeyMask) {
                    hotkeyOn = YES;
                } else {
                    hotkeyOn = NO;
                }
            }
        }];
        
        // Any other keys should cancel the moving or resizing event.
        keyUpMonitor = [NSEvent addGlobalMonitorForEventsMatchingMask:NSKeyDownMask handler:^(NSEvent *incomingEvent) {
            hotkeyOn = NO;
        }];
        [self listenForMouseActivity];
        return self;
    } else {
        return nil;
    }
}

-(void)setDoublePressBuffer:(NSInteger)val {
    doublePressBuffer = val;
}

-(NSInteger)getDoublePressBuffer {
    return doublePressBuffer;
}

-(void)resetDoublePressBuffer {
    doublePressBuffer = 0;
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
    if (enabled) {
        NSEvent *e = [NSEvent eventWithCGEvent:event];
        if (isLeftClick(e) || isRightClick(e)) {
            if (hotkeyOn) { // Steal the input if hotkey held
                [(__bridge InputHandler *)refcon mouseWasPressed];
                return NULL;
            }
            return event;
        } else if (isUp(e)) {
            if (hotkeyOn) {
                [(__bridge InputHandler *)refcon mouseWasReleased];
            }
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
    
    mouseMovedMonitor = [NSEvent addGlobalMonitorForEventsMatchingMask:NSLeftMouseDraggedMask|NSRightMouseDraggedMask|NSMouseMovedMask handler:^(NSEvent * event) {
        mousePosition = [NSEvent mouseLocation];
        mousePosition = [[NSScreen mainScreen] flipPoint:mousePosition];
        
        //NSLog(@"%d", mouseSideInWindow);
        if (isLeftDrag(event)) {
            [self mouseWasDragged:LEFT_MOUSE];
        }
        else if (isRightDrag(event)) {
            [self mouseWasDragged:RIGHT_MOUSE];
        }
    }];
    
}

/* TODO: Parameterize keyCode/event flag checks */

-(void)mouseWasPressed {
    
    mousePosition = [NSEvent mouseLocation];
    mousePosition = [[NSScreen mainScreen] flipPoint:mousePosition];
    NSUInteger mouseSideInWindow = [accessibilityWrapper mouseQuadrantForCurrentWindow:mousePosition];
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

-(void)mouseWasDragged:(BOOL)clickType {
    if (enabled && hotkeyOn && hasWindow) {
        if (clickType == LEFT_MOUSE) {
            NSPoint currentMousePosition = [NSEvent mouseLocation];
            currentMousePosition = [[NSScreen mainScreen] flipPoint:currentMousePosition];

            NSPoint windowTopLeft = [accessibilityWrapper getCurrentTopLeft];
            NSPoint windowDestination = windowTopLeft;
            windowDestination = currentMousePosition;
           
            windowDestination.x -= mouseHorizontalDistanceFromTopLeft;
            windowDestination.y -= mouseVerticalDistanceFromTopLeft;
           
            CGFloat screenRightEdge = [[NSScreen mainScreen] frame].size.width;
            NSSize windowSize = [accessibilityWrapper getCurrentSize];
            CGFloat windowRightEdge = windowDestination.x + windowSize.width;
            
            // Snap to left edge
            if (fabs(windowDestination.x) < 10)
                windowDestination.x = 0;
          
            // Snap to right edge
            if (fabs(screenRightEdge - windowRightEdge) < 10)
                windowDestination.x = screenRightEdge - windowSize.width;
            
            [accessibilityWrapper moveWindow: windowDestination];
        } else if (clickType == RIGHT_MOUSE) {
            mousePosition = [[NSScreen mainScreen] flipPoint:mousePosition];
            NSPoint currentMousePosition = [NSEvent mouseLocation];
            NSUInteger mouseSideInWindow = [accessibilityWrapper mouseQuadrantForCurrentWindow:currentMousePosition];
            CGFloat x = currentMousePosition.x;
            CGFloat y = currentMousePosition.y;
            
            CGFloat width = [accessibilityWrapper getCurrentSize].width;
            CGFloat height = [accessibilityWrapper getCurrentSize].height;
            
            // Normalize height and width. It's much easier to do this in a square.
            x *= (1/width);
            y *= (1/height);
            
            CGFloat deltaY = currentMousePosition.y - mousePosition.y;
            CGFloat deltaX = currentMousePosition.x - mousePosition.x;
            
            NSPoint windowPosition = [accessibilityWrapper getCurrentTopLeft];
            NSSize newSize = [accessibilityWrapper getCurrentSize];
           
            NSLog(@"dx: %f, dy: %f", deltaX, deltaY);
            switch (mouseSideInWindow) {
                case WINDOW_LEFT:
                    NSLog(@"Left");
                    newSize.width += deltaX;
                    windowPosition.x += deltaX;
                    [accessibilityWrapper resizeWindow:newSize];
                    break;
                    
                case WINDOW_RIGHT:
                    NSLog(@"Right");
                    newSize.width += deltaX;
                    [accessibilityWrapper resizeWindow:newSize];
                    break;
                    
                case WINDOW_TOP:
                    NSLog(@"Top");
                    newSize.height += deltaY;
                    windowPosition.y -= deltaY;
                    [accessibilityWrapper moveWindow: windowPosition];
                    [accessibilityWrapper resizeWindow:newSize];
                    break;
                case WINDOW_BOTTOM:
                    NSLog(@"Bottom");
                    newSize.height += deltaY;
                    [accessibilityWrapper resizeWindow:newSize];
                    break;
                default:
                    NSLog(@"None");
                    break;
            }
            mousePosition = currentMousePosition;
        }
    }
}

-(void)mouseWasReleased {
}

@end
