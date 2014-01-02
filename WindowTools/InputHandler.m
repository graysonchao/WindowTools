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
                            //NSLog(@"Enabled: %d", enabled);
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
        
        //NSLog(@"%d", [accessibilityWrapper mouseQuadrantForCurrentWindow:[NSEvent mouseLocation]]);
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
    mouseSideInWindow = [accessibilityWrapper mouseQuadrantForCurrentWindow:mousePosition];
    previousWindowSize = [accessibilityWrapper getCurrentSize];
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
        //NSLog(@"%f, %f", mousePosition.x, mousePosition.y);
        
        windowSize = [accessibilityWrapper getCurrentSize];
        windowPosition = [accessibilityWrapper getCurrentTopLeft];
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
            CGFloat screenBottomEdge = [[NSScreen mainScreen] frame].size.height;
            NSSize windowSize = [accessibilityWrapper getCurrentSize];
            CGFloat windowRightEdge = windowDestination.x + windowSize.width;
            CGFloat windowBottomEdge = windowDestination.y + windowSize.height;
            
            //NSLog(@"window %f screen %f", windowBottomEdge, screenBottomEdge);
            
            // Snap to left edge
            if (fabs(windowDestination.x) < 10)
                windowDestination.x = 0;
          
            // Snap to right edge
            if (fabs(screenRightEdge - windowRightEdge) < 10)
                windowDestination.x = screenRightEdge - windowSize.width;
            
            // Snap to bottom edge
            if (fabs(screenBottomEdge - windowBottomEdge) < 10)
                windowDestination.y = screenBottomEdge - windowSize.height;
           
            NSLog(@"%f", fabs(currentMousePosition.x - screenRightEdge));
            
            if (fabs(currentMousePosition.x) < 10) {
                [accessibilityWrapper resizeWindow: CGSizeMake(screenRightEdge / 2, screenBottomEdge)];
                windowDestination = CGPointMake(0, 0);
            }
            else if (fabs(currentMousePosition.x - screenRightEdge) < 10) {
                // Snap Right
                [accessibilityWrapper resizeWindow: CGSizeMake(screenRightEdge / 2, screenBottomEdge)];
                windowDestination = CGPointMake(screenRightEdge - [accessibilityWrapper getCurrentSize].width, 0);
            }
            
            else if (fabs(currentMousePosition.y < 10)) {
                [accessibilityWrapper resizeWindow: CGSizeMake(screenRightEdge, screenBottomEdge / 2)];
                windowDestination = CGPointMake(0, 0);
            }
            else if (fabs(currentMousePosition.y - screenBottomEdge) < 10) {
                [accessibilityWrapper resizeWindow: CGSizeMake(screenRightEdge, screenBottomEdge / 2)];
                windowDestination = CGPointMake(0, screenBottomEdge/2);
            }
            else {
                [accessibilityWrapper resizeWindow: previousWindowSize];
            }
            
            [accessibilityWrapper moveWindow: windowDestination];
            
        } else if (clickType == RIGHT_MOUSE) {
            NSPoint flippedMousePosition = [[NSScreen mainScreen] flipPoint:mousePosition];
            //NSLog(@"%f, %f", flippedMousePosition.x, flippedMousePosition.y);
            NSPoint currentMousePosition = [NSEvent mouseLocation];
            CGFloat x = currentMousePosition.x;
            CGFloat y = currentMousePosition.y;
            
            CGFloat width = [accessibilityWrapper getCurrentSize].width;
            CGFloat height = [accessibilityWrapper getCurrentSize].height;
            
            // Normalize height and width. It's much easier to do quadrants in a square.
            x *= (1/width);
            y *= (1/height);
            
            CGFloat deltaY = currentMousePosition.y - flippedMousePosition.y;
            CGFloat deltaX = currentMousePosition.x - flippedMousePosition.x;
            
            NSPoint currentWindowPosition = [accessibilityWrapper getCurrentTopLeft];
            NSSize newSize = [accessibilityWrapper getCurrentSize];
           
            switch (mouseSideInWindow) {
                case WINDOW_LEFT:
                    newSize.width = windowSize.width - deltaX;
                    currentWindowPosition.x = windowPosition.x + deltaX;
                    [accessibilityWrapper resizeWindow:newSize];
                    [accessibilityWrapper moveWindow:currentWindowPosition];
                    break;
                    
                case WINDOW_RIGHT:
                    newSize.width = windowSize.width + deltaX;
                    [accessibilityWrapper resizeWindow:newSize];
                    break;
                    
                case WINDOW_TOP:
                    newSize.height = windowSize.height + deltaY;
                    currentWindowPosition.y = windowPosition.y - deltaY;
                    [accessibilityWrapper resizeWindow:newSize];
                    [accessibilityWrapper moveWindow: currentWindowPosition];
                    break;
                case WINDOW_BOTTOM:
                    newSize.height  = windowSize.height - deltaY;
                    [accessibilityWrapper resizeWindow:newSize];
                    break;
                default:
                    //NSLog(@"None");
                    break;
            }
        }
    }
}

-(void)mouseWasReleased {
    previousWindowSize = [accessibilityWrapper getCurrentSize];
}

@end
