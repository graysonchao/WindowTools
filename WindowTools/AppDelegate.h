//
//  AppDelegate.h
//  WindowTools
//
//  Created by Grayson Chao on 11/5/13.
//  Copyright (c) 2013 Grayson Chao. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "AccessibilityWrapper.h"
#import "InputHandler.h"

@interface AppDelegate : NSObject <NSApplicationDelegate> {
    // Menu stuff
    IBOutlet NSMenu *trayMenu;
    IBOutlet NSMenuItem *about;
    IBOutlet NSMenuItem *config;
    IBOutlet NSMenuItem *quit;
    
    NSStatusItem *statusItem;
   
    // Doin' things stuff
    AccessibilityWrapper *AXWrapper;
    InputHandler *inputHandler;
    id mouseMonitor;
    id hotkeyMonitor;
}

@end
