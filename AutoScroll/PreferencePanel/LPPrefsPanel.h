//
//  LPPrefsPanel.h
//  QuickWindow
//
//  Created by Penny on 13-1-19.
//  Copyright (c) 2013年 Penny. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface LPPrefsPanel : NSObject <NSToolbarDelegate> {
    IBOutlet NSTabView*		tabView;
	NSMutableDictionary*	itemsList;    
}
- (void)orderFrontPrefsPanel:(id)sender;
- (void)selectedTabIndex:(NSInteger)index;
@end
