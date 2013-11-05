//
//  AppDelegate.m
//  WindowTools
//
//  Created by Grayson Chao on 11/5/13.
//  Copyright (c) 2013 Grayson Chao. All rights reserved.
//

#import "AppDelegate.h"
#import "SlateLogger.h"
#import "InputHandler.h"

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application
    statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    [statusItem setMenu:trayMenu];
    [statusItem setTitle:@"W"];
    [statusItem setHighlightMode:YES];
    
    AXWrapper = [[AccessibilityWrapper alloc] init];
    //inputHandler = [[InputHandler alloc] init];
    
    eventMonitor = [InputHandler createHotkeyMonitor];
    windowManager = [WindowManager createManager];
   
    SlateLogger(@"Got AXWrapper up. Current window %@",
                [AXWrapper getTitle]);

}

@end
