//
//  TMDHTMLTips.mm
//
//  Created by Ciarán Walsh on 2007-08-19.
//

#import "TMDHTMLTips.h"
#import <algorithm>

/*
"$DIALOG" tooltip --text '‘foobar’'
"$DIALOG" tooltip --html '<h1>‘foobar’</h1>'
*/

static CGFloat slow_in_out (CGFloat t)
{
	if(t < 1.0)
		t = 1.0 / (1.0 + exp((-t*12.0)+6.0));
	return std::min(t, 1.0);
}

NSString* const TMDTooltipPreferencesIdentifier = @"TM Tooltip";

@interface TMDHTMLTip ()
- (void)setContent:(NSString*)content transparent:(BOOL)transparent;
- (void)runUntilUserActivity:(id)sender;
- (void)stopAnimation:(id)sender;
@end

@implementation TMDHTMLTip
// ==================
// = Setup/teardown =
// ==================
+ (void)showWithContent:(NSString*)content atLocation:(NSPoint)point transparent:(BOOL)transparent
{
	TMDHTMLTip* tip = [TMDHTMLTip new];
	[tip setFrameTopLeftPoint:point];
	[tip setContent:content transparent:transparent]; // The tooltip will show itself automatically when the HTML is loaded
}

- (id)init;
{
	if(self = [self initWithContentRect:NSMakeRect(0, 0, 1, 1) styleMask:NSBorderlessWindowMask backing:NSBackingStoreBuffered defer:NO])
	{
		// Since we are relying on `setReleaseWhenClosed:`, we need to ensure that we are over-retained.
		CFBridgingRetain(self);
		[self setReleasedWhenClosed:YES];
		[self setAlphaValue:0.97];
		[self setOpaque:NO];
		[self setBackgroundColor:[NSColor colorWithDeviceRed:1.0 green:0.96 blue:0.76 alpha:1.0]];
		[self setBackgroundColor:[NSColor clearColor]];
		[self setHasShadow:YES];
		[self setLevel:NSStatusWindowLevel];
		[self setHidesOnDeactivate:YES];
		[self setIgnoresMouseEvents:YES];

		webPreferences = [[WebPreferences alloc] initWithIdentifier:TMDTooltipPreferencesIdentifier];
		[webPreferences setJavaScriptEnabled:YES];
		[webPreferences setPlugInsEnabled:NO];
		[webPreferences setUsesPageCache:NO];
		[webPreferences setCacheModel:WebCacheModelDocumentViewer];
		NSString* fontName = [[NSUserDefaults standardUserDefaults] stringForKey:@"fontName"];
		int fontSize = [[NSUserDefaults standardUserDefaults] integerForKey:@"fontSize"] ?: 11;
		NSFont* font = fontName ? [NSFont fontWithName:fontName size:fontSize] : [NSFont userFixedPitchFontOfSize:fontSize];
		[webPreferences setStandardFontFamily:[font familyName]];
		[webPreferences setDefaultFontSize:fontSize];
		[webPreferences setDefaultFixedFontSize:fontSize];

		webView = [[WebView alloc] initWithFrame:NSZeroRect];
		[webView setPreferencesIdentifier:TMDTooltipPreferencesIdentifier];
		[webView setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
		[webView setFrameLoadDelegate:self];
		[webView setDrawsBackground:NO];

		[self setContentView:webView];
	}
	return self;
}

// ===========
// = Webview =
// ===========
- (void)setContent:(NSString*)content transparent:(BOOL)transparent
{
	NSString* fullContent =	@"<html>"
				@"<head>"
				@"  <style type='text/css' media='screen'>"
				@"      body {"
				@"          background: %@;"
				@"          margin: 0;"
				@"          padding: 2px;"
				@"          overflow: hidden;"
				@"          display: table-cell;"
				@"          max-width: 800px;"
				@"      }"
				@"      pre { white-space: pre-wrap; }"
				@"  </style>"
				@"</head>"
				@"<body>%@</body>"
				@"</html>";

	fullContent = [NSString stringWithFormat:fullContent, transparent ? @"transparent" : @"#F6EDC3", content];
	[[webView mainFrame] loadHTMLString:fullContent baseURL:nil];
}

- (void)sizeToContent
{
	// Current tooltip position
	NSPoint pos = NSMakePoint([self frame].origin.x, [self frame].origin.y + [self frame].size.height);

	// Find the screen which we are displaying on
	NSRect screenFrame = [[NSScreen mainScreen] visibleFrame];
	for(NSScreen* candidate in [NSScreen screens])
	{
		if(NSPointInRect(pos, [candidate frame]))
		{
			screenFrame = [candidate visibleFrame];
			break;
		}
	}

	// The webview is set to a large initial size and then sized down to fit the content
	[self setContentSize:NSMakeSize(screenFrame.size.width - screenFrame.size.width / 3.0, screenFrame.size.height)];

	int height  = [[[webView windowScriptObject] evaluateWebScript:@"document.body.offsetHeight + document.body.offsetTop;"] intValue];
	int width   = [[[webView windowScriptObject] evaluateWebScript:@"document.body.offsetWidth + document.body.offsetLeft;"] intValue];

	[webView setFrameSize:NSMakeSize(width, height)];

	NSRect frame      = [self frameRectForContentRect:[webView frame]];
	frame.size.width  = std::min(NSWidth(frame), NSWidth(screenFrame));
	frame.size.height = std::min(NSHeight(frame), NSHeight(screenFrame));
	[self setFrame:frame display:NO];

	pos.x = std::max(NSMinX(screenFrame), std::min(pos.x, NSMaxX(screenFrame)-NSWidth(frame)));
	pos.y = std::min(std::max(NSMinY(screenFrame)+NSHeight(frame), pos.y), NSMaxY(screenFrame));

	[self setFrameTopLeftPoint:pos];
}

- (void)delayedSizeAndShow:(id)sender
{
	[self sizeToContent];
	[self orderFront:self];
	[self runUntilUserActivity:self];
}

- (void)webView:(WebView*)sender didFinishLoadForFrame:(WebFrame*)frame;
{
	[self performSelector:@selector(delayedSizeAndShow:) withObject:self afterDelay:0];
}

// ==================
// = Event handling =
// ==================
- (BOOL)shouldCloseForMousePosition:(NSPoint)aPoint
{
	CGFloat ignorePeriod = [[NSUserDefaults standardUserDefaults] floatForKey:@"OakToolTipMouseMoveIgnorePeriod"];
	if(-[didOpenAtDate timeIntervalSinceNow] < ignorePeriod)
		return NO;

	if(NSEqualPoints(mousePositionWhenOpened, NSZeroPoint))
	{
		mousePositionWhenOpened = aPoint;
		return NO;
	}

	NSPoint const& p = mousePositionWhenOpened;
	CGFloat deltaX = p.x - aPoint.x;
	CGFloat deltaY = p.y - aPoint.y;
	CGFloat dist = sqrt(deltaX * deltaX + deltaY * deltaY);

	CGFloat moveThreshold = [[NSUserDefaults standardUserDefaults] floatForKey:@"OakToolTipMouseDistanceThreshold"];
	return dist > moveThreshold;
}

- (void)runUntilUserActivity:(id)sender
{
	[self setValue:[NSDate date] forKey:@"didOpenAtDate"];
	mousePositionWhenOpened = NSZeroPoint;

	NSWindow* keyWindow = [NSApp keyWindow];
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
	[self setValue:[NSTimer scheduledTimerWithTimeInterval:0.02 target:self selector:@selector(animationTick:) userInfo:nil repeats:YES] forKey:@"animationTimer"];
}

- (void)animationTick:(id)sender
{
	CGFloat alpha = 0.97 * (1.0 - slow_in_out(-1.5 * [animationStart timeIntervalSinceNow]));
	if(alpha > 0.0)
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
		[animationTimer invalidate];
		[self setValue:nil forKey:@"animationTimer"];
		[self setValue:nil forKey:@"animationStart"];
		[self setAlphaValue:0.97];
	}
}
@end
