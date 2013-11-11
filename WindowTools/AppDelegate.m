//
//  AppDelegate.m
//  WindowTools
//
//  Created by Grayson Chao on 11/5/13.
//  Copyright (c) 2013 Grayson Chao. All rights reserved.
//

#import <Carbon/Carbon.h>
#import "AppDelegate.h"
#import "AccessibilityWrapper.h"
#import "PreferencesWindowController.h"
#import "InputHandler.h"

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application
    statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    [statusItem setMenu:trayMenu];
    [statusItem setTitle: @"W"];
    [statusItem setHighlightMode:YES];
    
    inputHandler = [[InputHandler alloc] initWithMoveKey: kVK_Command];
    
    [inputHandler listenForMouseActivity];
    
    NSLog(@"Got AXWrapper up. Current window %@",
                [AXWrapper getTitle]);

}

- (IBAction)openAboutWindow:(id)sender {
    aboutWindow = [[NSWindowController alloc] initWithWindowNibName:@"About"];
    [aboutWindow showWindow:nil];
}

- (IBAction)openPreferencesWindow:(id)sender {
    preferencesWindow = [[PreferencesWindowController alloc] initWithWindowNibName:@"Preferences"];
    [preferencesWindow showWindow:nil];
}

@end
