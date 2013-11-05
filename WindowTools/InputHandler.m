//
//  InputHandler.m
//  WindowTools
//
//  Created by Grayson Chao on 11/5/13.
//  Copyright (c) 2013 Grayson Chao. All rights reserved.
//

#import "InputHandler.h"
#import "SlateLogger.h"

@implementation InputHandler

int HOTKEY = 0x3A;

-(id) init {
    if (self) {
        return self;
    }
    return nil;
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

@end
