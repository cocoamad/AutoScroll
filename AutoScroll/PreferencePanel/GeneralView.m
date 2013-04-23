//
//  GeneralView.m
//  QuickWindow
//
//  Created by Penny on 13-1-19.
//  Copyright (c) 2013年 Penny. All rights reserved.
//

#import "GeneralView.h"
#import "Utities.h"

//#define HideKey 0


@implementation GeneralView

- (void)awakeFromNib
{
    [self layoutHotKeyControl];
}

- (void)layoutHotKeyControl
{
    _showPageControl = [[[SRRecorderControl alloc] initWithFrame: NSMakeRect(140, 153, 120, 23)] autorelease];
    _showPageControl.delegate = self;
    KeyCombo keyCombo;
    if ([[NSUserDefaults standardUserDefaults] objectForKey: kShowPageControl] == nil) {
        keyCombo.flags = 1048576;
        keyCombo.code = 18;
        [self saveHotkey: keyCombo Key: kShowPageControl];
    } else {
        NSDictionary *dict = [[NSUserDefaults standardUserDefaults] objectForKey: kShowPageControl];
        keyCombo.flags = [dict[@"flags"] intValue];
        keyCombo.code = [dict[@"code"] intValue];
    }
    [_showPageControl setKeyCombo: keyCombo];
    [_showPageControl setTag: 1];
    [self toggleHotKey: keyCombo PTHotKey: _showPageControlHotKey Target: self Action: @selector(hotKeyResponse:) Identifier: kShowPageControl];
    
    [self addSubview: _showPageControl];
}


- (void)saveHotkey:(KeyCombo)keyCombo Key:(NSString *)key
{
    NSInteger flags = keyCombo.flags;
    NSInteger code = keyCombo.code;
    NSDictionary *dict = @{@"flags" : @(flags), @"code" : @(code)};
    [[NSUserDefaults standardUserDefaults] setValue: dict forKey: key];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

#pragma mark PTHotKey Action
- (void)toggleHotKey:(KeyCombo)keyCombo PTHotKey:(PTHotKey *)hotKey Target:(id)target Action:(SEL)sel Identifier:(NSString*)identifier
{
    if (hotKey != nil)
	{
		[[PTHotKeyCenter sharedCenter] unregisterHotKey: hotKey];
		[hotKey release];
		hotKey = nil;
	}
    if (keyCombo.code != 0 && keyCombo.flags != 0) {
        hotKey = [[PTHotKey alloc] initWithIdentifier: identifier
                                                 keyCombo: [PTKeyCombo keyComboWithKeyCode: (int)keyCombo.code
                                                                                 modifiers: (int)SRCocoaToCarbonFlags(keyCombo.flags)]];
        [hotKey setName: identifier];
        [hotKey setTarget: target];
        [hotKey setAction: sel];
        [[PTHotKeyCenter sharedCenter] registerHotKey: hotKey];
    }
}

- (void)hotKeyResponse:(PTHotKey*)hotKey
{
    if ([[hotKey name] isEqualToString: kShowPageControl])
        [[NSNotificationCenter defaultCenter] postNotificationName: kNotification_HotKeyResponse object: kShowPageControl];
}

#pragma mark - HotKeyControl Delegate
- (BOOL)shortcutRecorder:(SRRecorderControl *)aRecorder isKeyCode:(NSInteger)keyCode andFlagsTaken:(NSUInteger)flags reason:(NSString **)aReason
{
    KeyCombo newKeyCombo;
    PTHotKey *hotKey;
    newKeyCombo.flags = flags;
    newKeyCombo.code = keyCode;
    [aRecorder setKeyCombo: newKeyCombo];
    NSString *key = nil;
    switch (aRecorder.tag) {
        case 1:
            key = kShowPageControl;
            hotKey = _showPageControlHotKey;
            break;
        default:
            break;
    }
    [self saveHotkey: newKeyCombo Key: key];
    [self toggleHotKey: newKeyCombo PTHotKey: hotKey Target: self Action: @selector(hotKeyResponse:) Identifier: key];
    return NO;
}

- (void)shortcutRecorder:(SRRecorderControl *)aRecorder keyComboDidChange:(KeyCombo)newKeyCombo
{

}

@end
