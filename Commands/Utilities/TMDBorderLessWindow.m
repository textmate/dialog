//
//  TMDBorderLessWindow.m
//  Dialog
//
//  Created by Joachim Mårtensson on 2007-08-14.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "TMDBorderLessWindow.h"


@implementation TMDBorderLessWindow

- (id)initWithContentRect:(NSRect)contentRect
                styleMask:(unsigned int)aStyle
                  backing:(NSBackingStoreType)bufferingType
                    defer:(BOOL)flag
{
	self = [super initWithContentRect:contentRect styleMask:NSBorderlessWindowMask backing:bufferingType defer:NO];

// [result setBackgroundColor:[NSColor clearColor]];
	[self setAlphaValue:0];
	[self setHasShadow:YES];
	[self setOpaque:NO];
//[self makeKeyWindow];
	return self;
}

- (BOOL)canBecomeMainWindow
{
	return YES;
}

- (BOOL) canBecomeKeyWindow
{
   return YES;
}

-(BOOL)acceptsFirstResponder
{
	return YES;
}

- (BOOL)showsResizeIndicator
{
	return NO;
}

-(BOOL)resignFirstResponder
{
	return NO;
}

@end
