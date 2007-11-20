//
//  TMDHTMLTips.mm
//
//  Created by Ciarán Walsh on 2007-08-19.
//  Copyright (c) 2007 __MyCompanyName__. All rights reserved.
//

#import "TMDHTMLTips.h"

/*
echo '‘foobarbaz’' | "$DIALOG" html-tip
*/

@implementation TMDHTMLTips
- (id)init
{
	if (self = [self initWithWindowNibName:@"HTMLTip"]) {
		content = nil;

		webPreferences = [[WebPreferences alloc] initWithIdentifier:TMD_TOOLTIP_PREFERENCES_IDENTIFIER];
		[webPreferences setJavaScriptEnabled:YES];
		NSString *fontFamily = [[NSUserDefaults standardUserDefaults] stringForKey:@"OakTextViewNormalFontName"];
		if (fontFamily == nil)
			fontFamily = @"Monaco";
		int fontSize = [[NSUserDefaults standardUserDefaults] integerForKey:@"OakTextViewNormalFontSize"];
		if (fontSize == 0)
			fontSize = 11;
		[webPreferences setStandardFontFamily:fontFamily];
		[webPreferences setDefaultFontSize:fontSize];
	}

	return self;
}

- (void)awakeFromNib
{
	if (content)
		[self setHTML:content];

	[webView setPreferencesIdentifier:TMD_TOOLTIP_PREFERENCES_IDENTIFIER];
	[webView setFrameLoadDelegate:self];
}

- (void)setHTML:(NSString *)html
{
	content = [html retain];

	if (![self isWindowLoaded])
		return;

	NSString *fullContent =	@"<html>"
				@"<head>"
				@"  <style type='text/css' media='screen'>"
				@"      body {"
				@"          background-color: #F6EDC3;"
				@"          border: 1px solid black;"
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
	NSPoint pos = NSMakePoint([[self window] frame].origin.x, [[self window] frame].origin.y + [[self window] frame].size.height);
	id wsc     = [webView windowScriptObject];
	int height = [[wsc evaluateWebScript:@"document.body.offsetHeight + document.body.offsetTop;"] intValue];
	int width  = [[wsc evaluateWebScript:@"document.body.offsetWidth + document.body.offsetLeft;"] intValue];

	[[self window] setContentSize:NSMakeSize(width, height)];
	
	int x_overlap = (pos.x + width) - [[NSScreen mainScreen] frame].size.width;
	if (x_overlap > 0)
		pos.x = pos.x - x_overlap;
	
	int y_overlap = pos.y - height;
	if (y_overlap < 0)
		pos.y = pos.y - y_overlap;
	[[self window] setFrameTopLeftPoint:pos];
}

- (void)fade
{
	if ([[self window] alphaValue] == 0.0) {
		[self close];
	} else {
		[[self window] setAlphaValue:[[self window] alphaValue] - 0.25];
		[self performSelector:@selector(fade) withObject:nil afterDelay:0.1];
	}
}

- (void)webView:(WebView *)sender didFinishLoadForFrame:(WebFrame *)frame
{
	[self sizeToContent];
	[self showWindow:self];
}

- (void)dealloc
{
	[content release];
	[webPreferences release];
	[super dealloc];
}
@end
