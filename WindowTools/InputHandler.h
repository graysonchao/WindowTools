//
//  InputHandler.h
//  WindowTools
//
//  Created by Grayson Chao on 11/5/13.
//  Copyright (c) 2013 Grayson Chao. All rights reserved.
//

#import <Foundation/Foundation.h>

CGEventRef catchClick(
    CGEventTapProxy proxy,
    CGEventType type,
    CGEventRef event,
    void *refcon
);

CFMachPortRef eventTap;

@interface InputHandler : NSObject

+(id)createHotkeyMonitor;
-(void)mouseWasPressed;
// Enable event tap and create it if needed
-(void)listenForMouseDown;

@end
