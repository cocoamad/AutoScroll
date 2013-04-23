//
//  LPPrefsPanel.m
//  QuickWindow
//
//  Created by Penny on 13-1-19.
//  Copyright (c) 2013年 Penny. All rights reserved.
//

#import "LPPrefsPanel.h"

@implementation LPPrefsPanel

- (id)init
{
    if (self = [super init]) {
        tabView = nil;
		itemsList = [[NSMutableDictionary alloc] init];
    }
    return self;
}

-(void)	dealloc
{
	[itemsList release];
	[super dealloc];
}


-(void)	awakeFromNib
{
	[self mapTabsToToolbar];
}

-(void) mapTabsToToolbar
{
    // Create a new toolbar instance, and attach it to our document window
    NSToolbar *toolbar =[[tabView window] toolbar];
	NSInteger itemCount = 0,
    x = 0;
	NSTabViewItem	*currPage = nil;
	
	if( toolbar == nil )   // No toolbar yet? Create one!
		toolbar = [[[NSToolbar alloc] initWithIdentifier: @"test.prefspanel.toolbar"] autorelease];
	
    // Set up toolbar properties: Allow customization, give a default display mode, and remember state in user defaults
    [toolbar setAllowsUserCustomization: NO];
    [toolbar setAutosavesConfiguration: NO];
    [toolbar setDisplayMode: NSToolbarDisplayModeIconAndLabel];
	
	// Set up item list based on Tab View:
	itemCount = [tabView numberOfTabViewItems];
	
	[itemsList removeAllObjects];	// In case we already had a toolbar.
	
	for( x = 0; x < itemCount; x++ )
	{
		NSTabViewItem*		theItem = [tabView tabViewItemAtIndex:x];
		NSString*			theIdentifier = [theItem identifier];
		NSString*			theLabel = [theItem label];
		
		[itemsList setObject: theLabel forKey: theIdentifier];
	}
    
    // We are the delegate
    [toolbar setDelegate: self];
    
    // Attach the toolbar to the document window
    [[tabView window] setToolbar: toolbar];
	
	// Set up window title:
	currPage = [tabView selectedTabViewItem];
	if( currPage == nil )
		currPage = [tabView tabViewItemAtIndex: 0];
	[[tabView window] setTitle: [currPage label]];
	
	if( [toolbar respondsToSelector: @selector(setSelectedItemIdentifier:)] )
		[toolbar setSelectedItemIdentifier: [currPage identifier]];
}

-(void)orderFrontPrefsPanel:(id)sender
{
	[[tabView window] makeKeyAndOrderFront: sender];
}

- (void)selectedTabIndex:(NSInteger)index
{
    [tabView selectTabViewItemAtIndex: index];
    NSTabViewItem *currPage = [tabView selectedTabViewItem];
	[[tabView window] setTitle: [currPage label]];
    NSToolbar *toolbar =[[tabView window] toolbar];
    if( [toolbar respondsToSelector: @selector(setSelectedItemIdentifier:)] )
		[toolbar setSelectedItemIdentifier: [currPage identifier]];
}


-(NSToolbarItem *) toolbar: (NSToolbar *)toolbar itemForItemIdentifier: (NSString *) itemIdent willBeInsertedIntoToolbar:(BOOL) willBeInserted
{
    // Required delegate method:  Given an item identifier, this method returns an item
    // The toolbar will use this method to obtain toolbar items that can be displayed in the customization sheet, or in the toolbar itself
    NSToolbarItem   *toolbarItem = [[[NSToolbarItem alloc] initWithItemIdentifier: itemIdent] autorelease];
    NSString*		itemLabel;
	
    if( (itemLabel = [itemsList objectForKey:itemIdent]) != nil )
	{
		// Set the text label to be displayed in the toolbar and customization palette
		[toolbarItem setLabel: itemLabel];
		[toolbarItem setPaletteLabel: itemLabel];
		[toolbarItem setTag:[tabView indexOfTabViewItemWithIdentifier:itemIdent]];
		
		// Set up a reasonable tooltip, and image   Note, these aren't localized, but you will likely want to localize many of the item's properties
		[toolbarItem setToolTip: itemLabel];
		[toolbarItem setImage: [NSImage imageNamed:itemIdent]];
		
		// Tell the item what message to send when it is clicked
		[toolbarItem setTarget: self];
		[toolbarItem setAction: @selector(changePanes:)];
    }
	else
	{
		// itemIdent refered to a toolbar item that is not provide or supported by us or cocoa
		// Returning nil will inform the toolbar this kind of item is not supported
		toolbarItem = nil;
    }
	
    return toolbarItem;
}

-(NSArray*) toolbarSelectableItemIdentifiers: (NSToolbar*)toolbar
{
	return [itemsList allKeys];
}

-(IBAction)	changePanes: (id)sender
{	
	[tabView selectTabViewItemAtIndex: [sender tag]];
	[[tabView window] setTitle: [sender label]];	
}

-(NSArray*) toolbarDefaultItemIdentifiers: (NSToolbar *) toolbar
{
	NSInteger					itemCount = [tabView numberOfTabViewItems],
    x;
	NSTabViewItem*		theItem = [tabView tabViewItemAtIndex:0];
	//NSMutableArray*	defaultItems = [NSMutableArray arrayWithObjects: [theItem identifier], NSToolbarSeparatorItemIdentifier, nil];
	NSMutableArray*	defaultItems = [NSMutableArray array];
	
	for( x = 0; x < itemCount; x++ )
	{
		theItem = [tabView tabViewItemAtIndex:x];
		
		[defaultItems addObject: [theItem identifier]];
	}
	
	return defaultItems;
}

-(NSArray*) toolbarAllowedItemIdentifiers: (NSToolbar *) toolbar
{
    NSMutableArray*		allowedItems = [[[itemsList allKeys] mutableCopy] autorelease];
	
	[allowedItems addObjectsFromArray: [NSArray arrayWithObjects: NSToolbarSeparatorItemIdentifier,
                                        NSToolbarSpaceItemIdentifier, NSToolbarFlexibleSpaceItemIdentifier,
                                        NSToolbarCustomizeToolbarItemIdentifier, nil] ];
	
	return allowedItems;
}


@end
