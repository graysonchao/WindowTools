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
    [statusItem setTitle: @"W"];
    [statusItem setHighlightMode:YES];
    
    inputHandler = [[InputHandler alloc] init];
    
    hotkeyMonitor = [InputHandler createHotkeyMonitor];
    [inputHandler listenForMouseActivity];
   
    NSLog(@"Got AXWrapper up. Current window %@",
                [AXWrapper getTitle]);

}

@end
