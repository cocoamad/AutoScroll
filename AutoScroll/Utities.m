//
//  Utities.m
//  iTips
//
//  Created by Penny on 12-9-22.
//  Copyright (c) 2012年 Penny. All rights reserved.
//

#import "Utities.h"
#import <Carbon/Carbon.h>
NSImage *loadImageByName(NSString *imageName)
{
    if (imageName) {
        NSString *imageFullPath = [[NSBundle mainBundle] pathForResource: imageName ofType: @"png"];
        if (imageFullPath)
            return [[[NSImage alloc] initWithContentsOfFile: imageFullPath] autorelease];
    }
    return nil;
}

CGPathRef createRoundRectPathInRect(CGRect rect, CGFloat radius)
{
    CGFloat mr = MIN(CGRectGetHeight(rect), CGRectGetWidth(rect));
    
    CGFloat _radius = MIN(radius, 0.5f * mr);
    
    CGRect innerRect = CGRectInset(rect, _radius, _radius);
    
    CGMutablePathRef path = CGPathCreateMutable();
    
    CGPathMoveToPoint(path, NULL, CGRectGetMinX(innerRect) - _radius, CGRectGetMinY(innerRect));
    
    CGPathAddArc(path, NULL, CGRectGetMinX(innerRect), CGRectGetMinY(innerRect), _radius, M_PI, 3 * M_PI_2, false);
    CGPathAddArc(path, NULL, CGRectGetMaxX(innerRect), CGRectGetMinY(innerRect), _radius, 3 * M_PI_2, 0, false);
    CGPathAddArc(path, NULL, CGRectGetMaxX(innerRect), CGRectGetMaxY(innerRect), _radius, 0, M_PI_2, false);
    CGPathAddArc(path, NULL, CGRectGetMinX(innerRect), CGRectGetMaxY(innerRect), _radius, M_PI_2, M_PI, false);
    CGPathCloseSubpath(path);
    
    return path;
}

CGPathRef createRoundRectStrokePath(CGRect rect, CGFloat radius)
{
    CGFloat mr = MIN(CGRectGetHeight(rect), CGRectGetWidth(rect));
    
    CGFloat _radius = MIN(radius, 0.5f * mr);
    
    CGRect innerRect = rect;//CGRectInset(rect, _radius, _radius);
    
    CGMutablePathRef path = CGPathCreateMutable();
    
    CGPathMoveToPoint(path, NULL, CGRectGetMinX(innerRect) - _radius, CGRectGetMinY(innerRect));
    
    CGPathAddArcToPoint(path, NULL,  CGRectGetMinX(innerRect), CGRectGetMinY(innerRect), CGRectGetMaxX(innerRect), CGRectGetMinY(innerRect), _radius);
    CGPathAddArcToPoint(path, NULL, CGRectGetMaxX(innerRect), CGRectGetMinY(innerRect), CGRectGetMaxX(innerRect), CGRectGetMaxY(innerRect), _radius);
    CGPathAddArcToPoint(path, NULL, CGRectGetMaxX(innerRect), CGRectGetMaxY(innerRect), 0, CGRectGetMaxY(innerRect), _radius);
    CGPathAddArcToPoint(path, NULL, 0, CGRectGetMaxY(innerRect), CGRectGetMinX(innerRect), 0, _radius);
    CGPathCloseSubpath(path);
    
    return path;
}

void ApplicationsInDirectory(NSString* searchPath, NSMutableArray* applications)
{
    BOOL isDir;
    NSFileManager* manager = [NSFileManager defaultManager];
    NSArray* files = [manager contentsOfDirectoryAtPath: searchPath error: nil];
    NSEnumerator* fileEnum = [files objectEnumerator];
    NSString* file = nil;
    while (file = [fileEnum nextObject]) {
        [manager changeCurrentDirectoryPath: searchPath];
        if ([manager fileExistsAtPath: file isDirectory: &isDir] && isDir) {
            NSString* fullpath = [searchPath stringByAppendingPathComponent: file];
            if ([[file pathExtension] isEqualToString: @"app"])
                [applications addObject: fullpath];
            else
                ApplicationsInDirectory(fullpath, applications);
        }
    }
}

NSArray* AllApplications(NSArray* searchPaths)
{
    NSMutableArray* applications = [NSMutableArray array];
    NSEnumerator* searchPathEnum = [searchPaths objectEnumerator];
    NSString* path = nil;
    while (path = [searchPathEnum nextObject])
        ApplicationsInDirectory(path, applications);
    return ([applications count]) ? applications : nil;
    
}

BOOL IsCommandKeyDownRightNow(void)
{
    return 0 != (GetCurrentKeyModifiers() & cmdKey);
}

NSImage *readFileIcon(NSString *appPath)
{
    NSImage* originalIcon = [[NSWorkspace sharedWorkspace]
                             iconForFile: appPath];
    NSRect resizedBounds = NSMakeRect(0, 0, 64, 64);
    NSImage* resizedIcon = [[[NSImage alloc] initWithSize: NSMakeSize(64, 64)] autorelease];
    
    [resizedIcon lockFocus];
    [originalIcon drawInRect:resizedBounds fromRect:NSZeroRect
                   operation:NSCompositeCopy fraction:1.0];
    [resizedIcon unlockFocus];
    return resizedIcon;
}

@implementation NSImage (Convert2CGImageRef)
- (CGImageRef)CGImageRef
{
    CGImageSourceRef source = CGImageSourceCreateWithData((CFDataRef)[self TIFFRepresentation], NULL);
    if (source) {
        CGImageRef maskRef =  CGImageSourceCreateImageAtIndex(source, 0, NULL);
        CFRelease(source);
        return maskRef;   // should release outside
    }
    return nil;
}
@end


@implementation NSColor (CGColor)

- (CGColorRef)CGColorRef
{
    const NSInteger numberOfComponents = [self numberOfComponents];
    CGFloat components[numberOfComponents];
    CGColorSpaceRef colorSpace = [[self colorSpace] CGColorSpace];
    
    [self getComponents:(CGFloat *)&components];
    
    return (CGColorRef)[(id)CGColorCreate(colorSpace, components) autorelease];
}
@end