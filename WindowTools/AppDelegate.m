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
#import <Carbon/Carbon.h>

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application
    statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    [statusItem setMenu:trayMenu];
    [statusItem setTitle: @"W"];
    [statusItem setHighlightMode:YES];
    
    inputHandler = [[InputHandler alloc] initWithMoveKey: kVK_Command resizeKey: kVK_Control];
    
    [inputHandler listenForMouseActivity];
    
    NSLog(@"Got AXWrapper up. Current window %@",
                [AXWrapper getTitle]);

}

- (IBAction)openAboutWindow:(id)sender {
    aboutWindow = [[NSWindowController alloc] initWithWindowNibName:@"About"];
    [aboutWindow showWindow:self];
}

@end
