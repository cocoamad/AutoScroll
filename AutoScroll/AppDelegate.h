//
//  AppDelegate.h
//  AutoScroll
//
//  Created by Penny on 13-1-23.
//  Copyright (c) 2013年 Penny. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ScrollBarWindow.h"
@interface AppDelegate : NSObject <NSApplicationDelegate, ScrollBarWindowDelegate>

@property (assign) IBOutlet NSWindow *window;

@end
