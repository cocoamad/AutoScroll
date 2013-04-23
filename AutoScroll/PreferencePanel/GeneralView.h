//
//  GeneralView.h
//  QuickWindow
//
//  Created by Penny on 13-1-19.
//  Copyright (c) 2013年 Penny. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "SRRecorderControl.h"
#import "PTHotKey.h"
#import "PTHotKeyCenter.h"

@interface GeneralView : NSView
@property(nonatomic, assign) SRRecorderControl *showPageControl;
@property(nonatomic, assign) PTHotKey          *showPageControlHotKey;

@end
