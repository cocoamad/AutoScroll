//
//  ScrollBarWindow.h
//  AutoScroll
//
//  Created by Penny on 13-1-26.
//  Copyright (c) 2013年 Penny. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class ScrollBarWindow;
@class  ContentView;
@protocol ScrollBarWindowDelegate <NSObject>
- (void)scrollBarGotoTop:(ScrollBarWindow *)window;
- (void)scrollBarGotoBottom:(ScrollBarWindow *)window;
- (void)scrollBarScrollToTop:(ScrollBarWindow *)window;
- (void)scrollBarScrollTOBottom:(ScrollBarWindow *)window;
@end


@interface ScrollBarWindow : NSPanel
@property (nonatomic, retain) ContentView *innerView;
- (void)detectScrollBar:(NSDictionary *)info;
- (void)lostScrollBar:(NSDictionary *)info;
@end


@interface ContentView : NSView
@property(nonatomic, assign) BOOL isHilight;
@property(nonatomic, assign) id<ScrollBarWindowDelegate> delegate;
@end