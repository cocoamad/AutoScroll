//
//  StatusBarView.m
//  iTips
//
//  Created by Penny on 12-9-22.
//  Copyright (c) 2012年 Penny. All rights reserved.
//

#import "StatusBarView.h"

@interface StatusBarView()
-(void)initStatusMenu;
@end

@implementation StatusBarView

- (id)initWithFrame:(NSRect)frame
{
        // Initialization code here.
    statusItem = [[[NSStatusBar systemStatusBar] statusItemWithLength: -2] retain];
    CGFloat itemWidth = [statusItem length];
    CGFloat itemHeight = [[NSStatusBar systemStatusBar] thickness];
    NSRect itemRect = NSMakeRect(0.0, 0.0, itemWidth, itemHeight);
    [statusItem setHighlightMode: YES];
    [self initStatusMenu];
    if (self = [super initWithFrame: itemRect]) {
        [statusItem setView: self];
        [statusItem setHighlightMode: YES]; 
        NSImage *normalImage = loadImageByName(@"star");
        normalIcon = [normalImage CGImageRef];
    }
    
    return self;
}

- (void)dealloc
{
    CGImageRelease(normalIcon);
    [statusMenu removeAllItems];
    [statusMenu release];
    [[NSStatusBar systemStatusBar] removeStatusItem: statusItem];
    [statusItem release];
    
    [super dealloc];
}

- (void)drawRect:(NSRect)dirtyRect
{
    [statusItem drawStatusBarBackgroundInRect: dirtyRect withHighlight: isHiLight];
    CGContextRef cxt = (CGContextRef)[[NSGraphicsContext currentContext] graphicsPort];
    
    NSSize iconSize = NSMakeSize(18, 18);
    NSRect bound = [self bounds];
    CGFloat iconX = roundf((float)(NSWidth(bound) - iconSize.width) / 2);
    CGFloat iconY = roundf((float)(NSHeight(bound) - iconSize.height) / 2);
    NSRect rect = NSMakeRect(iconX, iconY, 18, 18);
    CGContextDrawImage(cxt, rect, normalIcon);
}

#pragma mark Private Method
- (void)initStatusMenu
{
    statusMenu = [[NSMenu allocWithZone: [NSMenu menuZone]] initWithTitle: @"menu"];
    statusMenu.delegate = self;
    NSMenuItem *newItem = nil;
    
    newItem = [[NSMenuItem allocWithZone: [NSMenu menuZone]] initWithTitle: @"Preferences..." action: @selector(showPreference) keyEquivalent: @","];
    NSView *view = [[[NSView alloc] initWithFrame: NSMakeRect(0, 0, 64, 100)] autorelease];
    NSSlider *slider = [[[NSSlider alloc] initWithFrame: NSMakeRect(7, 3, 20, 95)] autorelease];
    [slider setMaxValue: 5];
    [slider setMinValue: 1.5];
    [slider setTickMarkPosition: NSTickMarkLeft];
    [slider setTarget: self];
    [slider setAction: @selector(speedChanged:)];
    
    [view addSubview: slider];
    [newItem setView: view];
    [newItem setTarget: self];
    [newItem setEnabled: YES];

    [statusMenu addItem: newItem];
    [newItem release];
//
//    [statusMenu addItem: [NSMenuItem separatorItem]];
//    
//    newItem = [[NSMenuItem allocWithZone: [NSMenu menuZone]] initWithTitle: @"About..." action: @selector(showAbout) keyEquivalent: @""];
//    [newItem setTarget: self];
//    [newItem setEnabled: YES];
//    
//    [statusMenu addItem: newItem];
//    [newItem release];
//    
//    newItem = [[NSMenuItem allocWithZone: [NSMenu menuZone]] initWithTitle: @"Quit" action: @selector(quit) keyEquivalent: @""];
//    [newItem setTarget: self];
//    [newItem setEnabled: YES];
//    [statusMenu addItem: newItem];
//    [newItem release];
    
}

- (void)speedChanged:(id)sender
{
    [[NSNotificationCenter defaultCenter] postNotificationName: kScrollBarSpeedChanged  object: [NSNumber numberWithFloat: [sender floatValue]]];
}
#pragma mark Mouse Event

- (void)rightMouseDown:(NSEvent *)theEvent
{
    isHiLight = YES;
    [self setNeedsDisplay: YES];
    [statusItem popUpStatusItemMenu: statusMenu];
    [super rightMouseDown: theEvent];
}

- (void)mouseDown:(NSEvent *)theEvent
{
    isHiLight = YES;
    [self setNeedsDisplay: YES];
    [statusItem popUpStatusItemMenu: statusMenu];
    [super mouseDown: theEvent];
}

- (void)mouseUp:(NSEvent *)theEvent
{
    isHiLight = NO;
    [self setNeedsDisplay: YES];
    [super mouseUp: theEvent];
}

#pragma mark NSMenu Delegate
- (void)menuWillOpen:(NSMenu *)menu 
{
    isHiLight = YES;
    [self setNeedsDisplay: YES];
}

- (void)menuDidClose:(NSMenu *)menu
{
    isHiLight = NO;
    [self setNeedsDisplay: YES];
}

#pragma mark NSMenu Action
-(void)showPreference
{
    [[NSNotificationCenter defaultCenter] postNotificationName: kNotification_ShowWindow object: @0];
}

- (void)showAbout
{
    [[NSNotificationCenter defaultCenter] postNotificationName: kNotification_ShowWindow object: @1];
}

- (void)quit
{
    [[NSApplication sharedApplication] terminate: nil];
}

@end