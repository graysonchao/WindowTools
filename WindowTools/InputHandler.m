//
//  InputHandler.m
//  WindowTools
//
//  Created by Grayson Chao on 11/5/13.
//  Copyright (c) 2013 Grayson Chao. All rights reserved.
//

#import "InputHandler.h"
#import "SlateLogger.h"

#define isClick(e) ([e type] == NSLeftMouseDown || [e type] == NSRightMouseDown)

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
        [(__bridge InputHandler *)refcon  listenForMouseDown];
        return NULL;
    }
    NSEvent *e = [NSEvent eventWithCGEvent:event];
    NSLog(@"Hello");
    if (isClick(e)) {
        if ([e modifierFlags] & (NSCommandKeyMask)) {
            [(__bridge InputHandler *)refcon mouseWasPressed];
            NSLog(@"Hello");
            return NULL;
        }
        return event;
    }
    return event;
}

- (void)listenForMouseDown {
    CGEventMask mask = CGEventMaskBit(kCGEventLeftMouseDown) | CGEventMaskBit(kCGEventRightMouseDown);
    
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
}

+(id) createHotkeyMonitor {
    // Watch for whenever the user presses alt
    id eventMonitor = [NSEvent addGlobalMonitorForEventsMatchingMask:NSFlagsChangedMask handler:^(NSEvent *incomingEvent) {
        if ([incomingEvent keyCode] == 58) { // L or R alt
            NSUInteger state = [incomingEvent modifierFlags];
            switch (state) {
                case 0x80120:
                    SlateLogger(@"Alt down yo");
                    //SlateLogger(@"%@", [incomingEvent description]);
                    break;
                case 0x100: // KeyUp
                    SlateLogger(@"Alt up yo!");
            }
        }
    }];
    return eventMonitor;
}

-(void)mouseWasPressed {
    NSLog(@"Mouse was pressed!");
}

@end
