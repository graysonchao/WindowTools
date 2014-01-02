//
//  AppDelegate.h
//  WindowTools
//
//  Created by Grayson Chao on 11/5/13.
//  Copyright (c) 2013 Grayson Chao. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class AccessibilityWrapper;
@class PreferencesWindowController;
@class InputHandler;

@interface AppDelegate : NSObject <NSApplicationDelegate> {
    // Menu stuff
    IBOutlet NSMenu *trayMenu;
    IBOutlet NSMenuItem *about;
    IBOutlet NSMenuItem *preferences;
    IBOutlet NSMenuItem *quit;
    
    NSStatusItem *statusItem;
    
    //Window stuff
    NSWindowController *aboutWindow;
    PreferencesWindowController *preferencesWindow;
   
    // Doin' things stuff
    AccessibilityWrapper *AXWrapper;
    InputHandler *inputHandler;
    id mouseMonitor;
    id hotkeyMonitor;
}

-(IBAction)openAboutWindow:(id)sender;
-(IBAction)openPreferencesWindow:(id)sender;

@end
