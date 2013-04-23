//
//  ScrollBarWindow.m
//  AutoScroll
//
//  Created by Penny on 13-1-26.
//  Copyright (c) 2013年 Penny. All rights reserved.
//

#import "ScrollBarWindow.h"
#import "Utities.h"

@interface ScrollBarWindow()
@property (assign) NSPoint initialLocation;
@end

@implementation ScrollBarWindow

- (id)initWithContentRect:(NSRect)contentRect styleMask:(NSUInteger)aStyle backing:(NSBackingStoreType)bufferingType defer:(BOOL)flag
{
    if (self = [super initWithContentRect: contentRect styleMask: aStyle backing:bufferingType defer: flag]) {
        
        self.backgroundColor = [NSColor clearColor];
        [self setOpaque: NO];
        self.level = kCGFloatingWindowLevel;
        self.innerView = [[[ContentView alloc] initWithFrame: NSMakeRect(0, 0, contentRect.size.width, contentRect.size.height)] autorelease];
        self.contentView = self.innerView;
    }
    return self;
}

- (void)detectScrollBar:(NSDictionary *)info
{
    self.innerView.isHilight = YES;
    
}

- (void)lostScrollBar:(NSDictionary *)info
{
    self.innerView.isHilight = NO;
}

/*
 Start tracking a potential drag operation here when the user first clicks the mouse, to establish
 the initial location.
 */
- (void)mouseDown:(NSEvent *)theEvent {
    // Get the mouse location in window coordinates.
    self.initialLocation = [theEvent locationInWindow];
}

/*
 Once the user starts dragging the mouse, move the window with it. The window has no title bar for
 the user to drag (so we have to implement dragging ourselves)
 */
- (void)mouseDragged:(NSEvent *)theEvent {

    NSRect screenVisibleFrame = [[NSScreen mainScreen] visibleFrame];
    NSRect windowFrame = [self frame];
    NSPoint newOrigin = windowFrame.origin;
    
    // Get the mouse location in window coordinates.
    NSPoint currentLocation = [theEvent locationInWindow];
    // Update the origin with the difference between the new mouse location and the old mouse location.
    newOrigin.x += (currentLocation.x - _initialLocation.x);
    newOrigin.y += (currentLocation.y - _initialLocation.y);
    
    // Don't let window get dragged up under the menu bar
    if ((newOrigin.y + windowFrame.size.height) > (screenVisibleFrame.origin.y + screenVisibleFrame.size.height)) {
        newOrigin.y = screenVisibleFrame.origin.y + (screenVisibleFrame.size.height - windowFrame.size.height);
    }
    
    // Move the window to the new location
    [self setFrameOrigin:newOrigin];
}

@end

@interface ContentView()
@property(nonatomic, assign) NSTimer *detectMouseTimer;
@end

@implementation  ContentView

- (id)initWithFrame:(NSRect)frameRect
{
    if (self = [super initWithFrame: frameRect]) {
        NSTrackingArea *area = [[NSTrackingArea alloc] initWithRect: self.bounds options: NSTrackingMouseMoved | NSTrackingMouseEnteredAndExited | NSTrackingActiveAlways
                                                              owner: self userInfo: nil];
        [self addTrackingArea: area];
        [area release];
        
        _isHilight = NO;
    }
    return self;
}

- (void)detectMousePosition:(NSTimer*)timer
{
    NSPoint globalPoint = [NSEvent mouseLocation];
    NSPoint point = [self convertPoint: globalPoint fromView: nil];
    NSPoint pointRelativeToScreen = [self.window
                                     convertRectToScreen: self.frame
                                     ].origin;
    point = NSMakePoint(point.x - pointRelativeToScreen.x, point.y - pointRelativeToScreen.y);
    
    if (point.y > self.bounds.size.height / 2) {
        if (_delegate && [_delegate respondsToSelector: @selector(scrollBarScrollToTop:)]) {
            [_delegate scrollBarScrollToTop: (ScrollBarWindow*)self.window];
        }
    } else {
        if (_delegate && [_delegate respondsToSelector: @selector(scrollBarScrollTOBottom:)]) {
            [_delegate scrollBarScrollTOBottom: (ScrollBarWindow*)self.window];
        }
    }
}

#pragma mark Mouse Event

- (void)mouseEntered:(NSEvent *)theEvent
{
    if (_isHilight) {
        _detectMouseTimer = [[NSTimer scheduledTimerWithTimeInterval: .05 target: self selector: @selector(detectMousePosition:) userInfo: nil repeats: YES] retain];
        [_detectMouseTimer fire];
    }
}

- (void)mouseExited:(NSEvent *)theEvent
{
    if (_detectMouseTimer) {
        [_detectMouseTimer invalidate];
        [_detectMouseTimer release];
        _detectMouseTimer = nil;
    }
}

- (void)mouseDown:(NSEvent *)theEvent
{
    NSPoint point = [theEvent locationInWindow];
    if (point.y < 20) {
        if (_delegate && [_delegate respondsToSelector: @selector(scrollBarGotoBottom:)]) {
            [_delegate scrollBarGotoBottom:(ScrollBarWindow *)self.window];
        }
    } else if (point.y > 80) {
        if (_delegate && [_delegate respondsToSelector: @selector(scrollBarGotoTop:)]) {
            [_delegate scrollBarGotoTop:(ScrollBarWindow *)self.window];
        }
    }
    [super mouseDown: theEvent];
}

- (void)setIsHilight:(BOOL)isHilight
{
    if (_isHilight != isHilight) {
        _isHilight = isHilight;
        [self setNeedsDisplay: YES];
    }
}

- (void)drawRect:(NSRect)dirtyRect
{
    CGContextRef ctx = [NSGraphicsContext currentContext].graphicsPort;
    
    CGContextSaveGState(ctx);
    
    CGContextSaveGState(ctx);
    if (_isHilight)
        CGContextSetFillColorWithColor(ctx, [NSColor redColor].CGColorRef);
    else
        CGContextSetFillColorWithColor(ctx, [NSColor grayColor].CGColorRef);
    CGPathRef path = CGPathCreateWithEllipseInRect(self.bounds, nil);
    CGContextSetAlpha(ctx, .5);
    CGContextAddPath(ctx, path);
    CGContextDrawPath(ctx, kCGPathFill);
    [self.window setHasShadow: YES];
}
@end