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

	[self setHasShadow:YES];

	return self;
}
@end