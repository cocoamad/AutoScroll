//
//  AppDelegate.m
//  AutoScroll
//
//  Created by Penny on 13-1-23.
//  Copyright (c) 2013年 Penny. All rights reserved.
//

#import "AppDelegate.h"
#import "UIElementUtilities.h"
#import "StatusBarView.h"
#import "LPPrefsPanel.h"
#import "ScrollBarWindow.h"
@interface AppDelegate()

@property (nonatomic, assign) StatusBarView *barView;
@property (nonatomic, assign) IBOutlet LPPrefsPanel *prefsPanel;
@property (nonatomic, assign) AXObserverRef observer;


@property (nonatomic, assign) NSPoint lastMousePoint;
@property (nonatomic, assign) AXUIElementRef currentUIElement;
@property (nonatomic, assign) AXUIElementRef systemWideElement;

@property (nonatomic, assign) AXUIElementRef focusWindowElement;

@property (nonatomic, assign) NSTimer *autoScrollTimer;
@property (nonatomic, assign) NSTimer *detectMouseHoldTimer;
@property (nonatomic, assign) pid_t safariPid;
@property (nonatomic, assign) NSSize webContentSize;

@property (nonatomic, assign) CGFloat scrollRate;
@property (nonatomic, assign) BOOL scrollWhenFocus;
@property (nonatomic, assign) BOOL scrollWhenDetectedLink;
@property (nonatomic, assign) ScrollBarWindow *scrollBarWindow;

@end

@implementation AppDelegate

- (void)dealloc
{
    if (_systemWideElement) CFRelease(_systemWideElement);
    if (_currentUIElement) CFRelease(_currentUIElement);
    [super dealloc];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application
    _barView = [[StatusBarView alloc] initWithFrame: NSMakeRect(0, 0, 24, 18)];
    
    [self registerNotification];
    
    [self setupAccess];
    
    _scrollRate = 1.2f;
    _scrollWhenFocus = NO;
    _scrollWhenDetectedLink = YES;
    
    _systemWideElement = AXUIElementCreateSystemWide();
    [self performTimerBasedUpdate];
    
    if (_scrollBarWindow == nil) {
        _scrollBarWindow = [[ScrollBarWindow alloc] initWithContentRect: NSMakeRect(500, 400, 100, 100) styleMask: NSNonactivatingPanelMask backing: NSBackingStoreBuffered defer: YES];
        _scrollBarWindow.innerView.delegate = self;
        [_scrollBarWindow orderFront: self];
    }

}
#pragma mark Scroll Bar Delegate
- (void)scrollBarScrollToTop:(ScrollBarWindow *)window
{
    _scrollRate = -fabs(_scrollRate);
    [self autoScroll: nil];
    
}

- (void)scrollBarScrollTOBottom:(ScrollBarWindow *)window
{
    _scrollRate = fabs(_scrollRate);
    [self autoScroll: nil];
}

- (void)scrollBarGotoTop:(ScrollBarWindow *)window
{
    [UIElementUtilities setStringValue: @"0" forAttribute: @"AXValue" ofUIElement: _currentUIElement];
}

- (void)scrollBarGotoBottom:(ScrollBarWindow *)window
{
    [UIElementUtilities setStringValue: @"1" forAttribute: @"AXValue" ofUIElement: _currentUIElement];
}


#pragma mark init
- (void)registerNotification
{
    [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(showPreference:)
                                                 name: kNotification_ShowWindow object: nil];
    [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(hotKey:)
                                                 name: kNotification_HotKeyResponse object: nil];
//    kScrollBarSpeedChanged
    [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(changedScrollBarRate:)
                                                 name: kScrollBarSpeedChanged object: nil];
}

- (void)performTimerBasedUpdate
{
    [self updateCurrentUIElement];
    
    [NSTimer scheduledTimerWithTimeInterval: .1 target: self selector: @selector(performTimerBasedUpdate) userInfo:nil repeats:NO];
}


- (void)setupAccess
{
    if (!AXAPIEnabled())
    {
        
        NSAlert *alert = [[[NSAlert alloc] init] autorelease];
        
        [alert setAlertStyle:NSWarningAlertStyle];
        [alert setMessageText:@"QuickWindow requires that the Accessibility API be enabled."];
        [alert setInformativeText:@"Would you like to launch System Preferences so that you can turn on \"Enable access for assistive devices\"?"];
        [alert addButtonWithTitle:@"Open System Preferences"];
        [alert addButtonWithTitle:@"Continue Anyway"];
        [alert addButtonWithTitle:@"Quit QuickWindow"];
        
        NSInteger alertResult = [alert runModal];
        
        switch (alertResult) {
            case NSAlertFirstButtonReturn: {
                NSArray *paths = NSSearchPathForDirectoriesInDomains(NSPreferencePanesDirectory, NSSystemDomainMask, YES);
                if ([paths count] == 1) {
                    NSURL *prefPaneURL = [NSURL fileURLWithPath:[[paths objectAtIndex:0] stringByAppendingPathComponent:@"UniversalAccessPref.prefPane"]];
                    [[NSWorkspace sharedWorkspace] openURL:prefPaneURL];
                }
            }
                break;
                
            case NSAlertSecondButtonReturn: // just continue
            default:
                break;
            case NSAlertThirdButtonReturn:
                [NSApp terminate: self];
                return;
                break;
        }
    }
}

#pragma preference panel
- (void)showPreference:(NSNotification*)n
{
    NSInteger index = [[n object] intValue];
    [_prefsPanel selectedTabIndex: index];
    [_prefsPanel orderFrontPrefsPanel: self];
}

#pragma mark notification
- (void)hotKey:(NSNotification*)n
{
    AXUIElementRef focusWindowRef = NULL;
    AXUIElementCopyAttributeValue(_systemWideElement, (CFStringRef)NSAccessibilityFocusedUIElementAttribute, (CFTypeRef*)&focusWindowRef);
    if (focusWindowRef) {
        pid_t focus_pid = [UIElementUtilities processIdentifierOfUIElement: focusWindowRef];
        if (focus_pid == _safariPid) {
            NSLog(@"safari is focus~~, pid = %d, focus pid = %d", _safariPid, focus_pid);
            if (_currentUIElement) {
                if (_autoScrollTimer)
                    [self stopAutoScroll];
                else
                    [self startAutoScroll];
            }
        }
        CFRelease(focusWindowRef);
    }

    

    
}

- (void)changedScrollBarRate:(NSNotification*)n
{
    CGFloat speedValue = [[n object] floatValue];
    _scrollRate = speedValue;
}

#pragma mark scroll
- (void)stopAutoScroll
{
    if (_autoScrollTimer) {
        [_autoScrollTimer invalidate];
        [_autoScrollTimer release];
        _autoScrollTimer = nil;
        NSLog(@"scroll stop~~");
    }
}

- (void)startAutoScroll
{
    _autoScrollTimer = [[NSTimer scheduledTimerWithTimeInterval: .05 target: self selector: @selector(autoScroll:) userInfo: nil repeats: YES] retain];
    [_autoScrollTimer fire];
    NSLog(@"scroll start~~");
}


- (void)autoScroll:(NSTimer*)timer
{
    void (^scrollBlock)(void) = ^(void){
        
        void (^Block)(void) = ^(void){
            // need fixed............................
            NSNumber *value =  [UIElementUtilities valueOfAttribute: @"AXValue" ofUIElement: _currentUIElement];

            CGFloat percent = _scrollRate  / _webContentSize.height;
            NSLog(@"get value is %f", percent);
            percent += [value floatValue];
            NSLog(@"set value is %f", percent);
            if (percent <= 1 && percent >= 0.000001) {
                NSString *setValue = [NSString stringWithFormat: @"%f", percent];
               
                [UIElementUtilities setStringValue: setValue forAttribute: @"AXValue" ofUIElement: _currentUIElement];
            }
        };
        
        if (_scrollWhenDetectedLink) {
            Block();
        } else {
            NSPoint cocoaPoint = [NSEvent mouseLocation];
            if (!NSEqualPoints(cocoaPoint, _lastMousePoint)) {
                CGPoint carbonPoint = [UIElementUtilities carbonScreenPointFromCocoaScreenPoint: cocoaPoint];
                if (![self positionIsLink: carbonPoint]) {
                    Block();
                }
            }
        }

    };
    
    if (_scrollWhenFocus) {
        if ([self safariIsFocus])
            scrollBlock();
    }
    else
        scrollBlock();
}


- (void)updateCurrentUIElement
{
    // The current mouse position with origin at top right.
    NSPoint cocoaPoint = [NSEvent mouseLocation];

    // Only ask for the UIElement under the mouse if has moved since the last check.
    if (!NSEqualPoints(cocoaPoint, _lastMousePoint)) {
        CGPoint pointAsCGPoint = [UIElementUtilities carbonScreenPointFromCocoaScreenPoint: cocoaPoint];
        AXUIElementRef newElement = NULL;
        if(kAXErrorSuccess == AXUIElementCopyElementAtPosition( _systemWideElement, pointAsCGPoint.x, pointAsCGPoint.y, &newElement ) && newElement) {
            AXUIElementRef scrollBar = [self findAXScrollBarElement: newElement];
            // Ask Accessibility API for UI Element under the mouse
            if (scrollBar && (([self currentUIElement] == NULL || ! CFEqual( [self currentUIElement], scrollBar )))) {
                [self setCurrentUIElement: scrollBar];
                _lastMousePoint = cocoaPoint;
                

                [_scrollBarWindow detectScrollBar: nil];
            }
            
            if (scrollBar) {
                AXUIElementRef webArea = [self findAXWebAreaElement: scrollBar];
                if (webArea) {
                    id elementSize = [UIElementUtilities valueOfAttribute:NSAccessibilitySizeAttribute ofUIElement: webArea];
                    AXValueGetValue((AXValueRef)elementSize, kAXValueCGSizeType, &_webContentSize);
                } else _webContentSize = NSZeroSize;
                
                NSLog(@"detectd %@ web content size %@", [UIElementUtilities roleOfUIElement: scrollBar], NSStringFromSize(_webContentSize));
            }
            CFRelease(newElement);
        }
    }
}

- (AXUIElementRef)findAXScrollBarElement:(AXUIElementRef)element
{    
    pid_t pid = [UIElementUtilities processIdentifierOfUIElement: element];
    AXUIElementRef applicationElement = AXUIElementCreateApplication(pid);
    if (applicationElement) {
        NSString *applicaitonName = [UIElementUtilities titleOfUIElement: applicationElement];
        if ([applicaitonName isEqualToString: @"Safari"]) {
            _safariPid = pid;
            CFRelease(applicationElement);
            AXUIElementRef windowElement = [UIElementUtilities windowUIElement: element];
            if (windowElement) {
                NSRect windowFrame = [UIElementUtilities flippedScreenBounds: [UIElementUtilities frameOfUIElement: windowElement]];
                NSPoint detectPoint = NSMakePoint(NSMaxX(windowFrame) - 5, NSMidY(windowFrame));
                AXUIElementRef detectElement = NULL;
                AXUIElementCopyElementAtPosition( _systemWideElement, detectPoint.x, detectPoint.y, &detectElement);
                if (detectElement && [[UIElementUtilities roleOfUIElement: detectElement] isEqualToString: @"AXScrollBar"])
                    return detectElement;
            }
        }
    }
    return NULL;
}

- (AXUIElementRef)findAXWebAreaElement:(AXUIElementRef)scrollBar
{
    AXUIElementRef parent = [UIElementUtilities parentOfUIElement: scrollBar];
    if (parent) {
        NSArray *childrens = [UIElementUtilities valueOfAttribute: @"AXChildren" ofUIElement: parent];
        if (childrens && childrens.count > 0) {
            for (id obj in childrens) {
                AXUIElementRef element = (AXUIElementRef)obj;
                if ([[UIElementUtilities roleOfUIElement: element] isEqualToString: @"AXWebArea"]) {
                    return element;
                }
            }
        }
    }
    return NULL;
}

#pragma mark pravite method
- (BOOL)safariIsFocus
{
    AXUIElementRef focusWindowRef = NULL;
    AXUIElementCopyAttributeValue(_systemWideElement, (CFStringRef)NSAccessibilityFocusedUIElementAttribute, (CFTypeRef*)&focusWindowRef);
    if (focusWindowRef) {
        pid_t focus_pid = [UIElementUtilities processIdentifierOfUIElement: focusWindowRef];
        if (focus_pid == _safariPid) {
            return YES;
        }
        CFRelease(focusWindowRef);
    }
    return NO;
}

- (BOOL)positionIsLink:(NSPoint)point
{
    AXUIElementRef newElement = NULL;
    if(kAXErrorSuccess == AXUIElementCopyElementAtPosition( _systemWideElement, point.x, point.y, &newElement ) && newElement) {
        if ([UIElementUtilities processIdentifierOfUIElement: newElement] == _safariPid) {
            AXUIElementRef parent = [UIElementUtilities parentOfUIElement: newElement];
            if ([[UIElementUtilities roleOfUIElement: parent] isEqualToString: @"AXLink"]) {
                CFRelease(newElement);
                return YES;
            }
        }
    }
    return NO;
}

#pragma mark observer window
void MyAXObserverCallback( AXObserverRef observer, AXUIElementRef element,
                          CFStringRef notificationName, void * contextData )
{
    // handle the notification appropriately
    // when using ObjC, your contextData might be an object, therefore you can do:
    static int index = 0;
    NSLog(@"Name:%d %@ %@",index++, notificationName, [UIElementUtilities roleOfUIElement: element]);
    // now do something with obj
}

- (void)removeSafariObserver:(AXObserverRef)observer ApplicationElement:(AXUIElementRef)app
{
    if (_observer) {
        AXObserverRemoveNotification( _observer, app, kAXUIElementDestroyedNotification);
        CFRunLoopRemoveSource([[NSRunLoop currentRunLoop] getCFRunLoop], AXObserverGetRunLoopSource(_observer),
                              kCFRunLoopDefaultMode );
        
        CFRunLoopAddSource( [[NSRunLoop currentRunLoop] getCFRunLoop],
                           AXObserverGetRunLoopSource(_observer),
                           kCFRunLoopDefaultMode );
        
        CFRelease(_observer);
        _observer = NULL;
    }
}


- (void)addSafariObserver:(pid_t)pid ApplicationElement:(AXUIElementRef)app
{
    if (_observer == nil || pid != _safariPid) {
        _safariPid = pid;
        
        [self removeSafariObserver: _observer ApplicationElement: app];
        
        AXError err = AXObserverCreate(pid, MyAXObserverCallback, &_observer );
        if ( err != kAXErrorSuccess )
            NSLog(@"error");
        
        AXObserverAddNotification( _observer, app, kAXUIElementDestroyedNotification, self );
        
        CFRunLoopAddSource( [[NSRunLoop currentRunLoop] getCFRunLoop],
                           AXObserverGetRunLoopSource(_observer),
                           kCFRunLoopDefaultMode );}
    
}
@end
