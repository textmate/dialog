//
//  TMDHTMLTips.mm
//
//  Created by Ciarán Walsh on 2007-08-19.
//  Copyright (c) 2007 __MyCompanyName__. All rights reserved.
//

#import "TMDHTMLTips.h"
#import <algorithm>

/*
echo '‘Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.’' | "$DIALOG" html-tip
*/

static float slow_in_out (float t)
{
	if(t < 1.0f)
		t = 1.0f / (1.0f + exp((-t*12.0f)+6.0f));
	return std::min(t, 1.0f);
}

const NSString* TMDTooltipPreferencesIdentifier = @"TM Tooltip";

@interface TMDHTMLTip (Private)
- (void)setHTML:(NSString *)html;
- (void)runUntilUserActivity;
- (void)stopAnimation:(id)sender;
@end

@implementation TMDHTMLTip
// ==================
// = Setup/teardown =
// ==================
+ (void)showWithHTML:(NSString*)content atLocation:(NSPoint)point forScreen:(NSScreen*)screen;
{
	TMDHTMLTip* tip = [TMDHTMLTip new];
	[tip setFrameTopLeftPoint:point];
	[tip setHTML:content]; // The tooltip will show itself automatically when the HTML is loaded
}

- (id)init
{
	NSRect frame = [[NSScreen mainScreen] frame];
	frame.size.width -= frame.size.width / 3.0f;
	if(self = [super initWithContentRect:frame styleMask:NSBorderlessWindowMask backing:NSBackingStoreBuffered defer:NO])
	{
		[self setReleasedWhenClosed:YES];
		[self setAlphaValue:0.97f];
		[self setOpaque:NO];
		[self setBackgroundColor:[NSColor colorWithDeviceRed:1.0f green:0.96f blue:0.76f alpha:1.0f]];
		[self setHasShadow:YES];
		[self setLevel:NSStatusWindowLevel];
		[self setHidesOnDeactivate:YES];
		[self setIgnoresMouseEvents:YES];

		webPreferences = [[WebPreferences alloc] initWithIdentifier:TMDTooltipPreferencesIdentifier];
		[webPreferences setJavaScriptEnabled:YES];
		NSString *fontFamily = [[NSUserDefaults standardUserDefaults] stringForKey:@"OakTextViewNormalFontName"];
		if(fontFamily == nil)
			fontFamily = @"Monaco";
		int fontSize = [[NSUserDefaults standardUserDefaults] integerForKey:@"OakTextViewNormalFontSize"];
		if(fontSize == 0)
			fontSize = 11;
		[webPreferences setStandardFontFamily:fontFamily];
		[webPreferences setDefaultFontSize:fontSize];

		webView = [[WebView alloc] initWithFrame:[self frame]];
		[webView setPreferencesIdentifier:TMDTooltipPreferencesIdentifier];
		[webView setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
		[webView setFrameLoadDelegate:self];

		[self setContentView:webView];
	}
	return self;
}

- (void)dealloc
{
	[didOpenAtDate release];
	[webView release];
	[webPreferences release];
	[super dealloc];
}

// ===========
// = Webview =
// ===========
- (void)setHTML:(NSString *)html
{
	NSString *fullContent =	@"<html>"
				@"<head>"
				@"  <style type='text/css' media='screen'>"
				@"      body {"
				@"          background-color: #F6EDC3;"
				@"          margin: 0;"
				@"          padding: 2px;"
				@"          overflow: hidden;"
				@"          display: table-cell;"
				@"      }"
				@"  </style>"
				@"</head>"
				@"<body>%@</body>"
				@"</html>";
	fullContent = [NSString stringWithFormat:fullContent, html];
	[[webView mainFrame] loadHTMLString:fullContent baseURL:nil];
}

- (void)sizeToContent
{
 	NSPoint pos = NSMakePoint([self frame].origin.x, [self frame].origin.y + [self frame].size.height);
	id wsc      = [webView windowScriptObject];
	int height  = [[wsc evaluateWebScript:@"document.body.offsetHeight + document.body.offsetTop;"] intValue];
	int width   = [[wsc evaluateWebScript:@"document.body.offsetWidth + document.body.offsetLeft;"] intValue];
	
	[self setContentSize:NSMakeSize(width, height)];
	
	int x_overlap = (pos.x + width) - [[NSScreen mainScreen] frame].size.width;
	if(x_overlap > 0)
		pos.x = pos.x - x_overlap;
	
	int y_overlap = pos.y - height;
	if(y_overlap < 0)
		pos.y = pos.y - y_overlap;
	[self setFrameTopLeftPoint:pos];
}

- (void)webView:(WebView*)sender didFinishLoadForFrame:(WebFrame*)frame;
{
	[self sizeToContent];
	[self orderFront:self];
	[self performSelector:@selector(runUntilUserActivity) withObject:nil afterDelay:0];
}

// ==================
// = Event handling =
// ==================
- (BOOL)shouldCloseForMousePosition:(NSPoint)aPoint
{
	float ignorePeriod = [[NSUserDefaults standardUserDefaults] floatForKey:@"OakToolTipMouseMoveIgnorePeriod"];
	if(-[didOpenAtDate timeIntervalSinceNow] < ignorePeriod)
		return NO;

	if(NSEqualPoints(mousePositionWhenOpened, NSZeroPoint))
	{
		mousePositionWhenOpened = aPoint;
		return NO;
	}

	NSPoint const& p = mousePositionWhenOpened;
	float deltaX = p.x - aPoint.x;
	float deltaY = p.y - aPoint.y;
	float dist = sqrtf(deltaX * deltaX + deltaY * deltaY);

	float moveThreshold = [[NSUserDefaults standardUserDefaults] floatForKey:@"OakToolTipMouseDistanceThreshold"];
	return dist > moveThreshold;
}

- (void)runUntilUserActivity;
{
	[self setValue:[NSDate date] forKey:@"didOpenAtDate"];
	mousePositionWhenOpened = NSZeroPoint;

	NSWindow* keyWindow = [[NSApp keyWindow] retain];
	BOOL didAcceptMouseMovedEvents = [keyWindow acceptsMouseMovedEvents];
	[keyWindow setAcceptsMouseMovedEvents:YES];

	while(NSEvent* event = [NSApp nextEventMatchingMask:NSAnyEventMask untilDate:[NSDate distantFuture] inMode:NSDefaultRunLoopMode dequeue:YES])
	{
		[NSApp sendEvent:event];

		if([event type] == NSLeftMouseDown || [event type] == NSRightMouseDown || [event type] == NSOtherMouseDown || [event type] == NSKeyDown || [event type] == NSScrollWheel)
			break;

		if([event type] == NSMouseMoved && [self shouldCloseForMousePosition:[NSEvent mouseLocation]])
			break;

		if(keyWindow != [NSApp keyWindow] || ![NSApp isActive])
			break;
	}

	[keyWindow setAcceptsMouseMovedEvents:didAcceptMouseMovedEvents];
	[keyWindow release];

	[self orderOut:self];
}

// =============
// = Animation =
// =============
- (void)orderOut:(id)sender
{
	if(![self isVisible] || animationTimer)
		return;

	[self stopAnimation:self];
	[self setValue:[NSDate date] forKey:@"animationStart"];
	[self setValue:[NSTimer scheduledTimerWithTimeInterval:0.02f target:self selector:@selector(animationTick:) userInfo:nil repeats:YES] forKey:@"animationTimer"];
}

- (void)animationTick:(id)sender
{
	float alpha = 0.97f * (1.0f - slow_in_out(-1.5 * [animationStart timeIntervalSinceNow]));
	if(alpha > 0.0f)
	{
		[self setAlphaValue:alpha];
	}
	else
	{
		[super orderOut:self];
		[self stopAnimation:self];
		[self close];
	}
}

- (void)stopAnimation:(id)sender;
{
	if(animationTimer)
	{
		[[self retain] autorelease];
		[animationTimer invalidate];
		[self setValue:nil forKey:@"animationTimer"];
		[self setValue:nil forKey:@"animationStart"];
		[self setAlphaValue:0.97f];
	}
}
@end
