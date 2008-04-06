#import <Cocoa/Cocoa.h>
#import <Foundation/Foundation.h>
#import "../../TMDCommand.h"
#import "../../Dialog2.h"
#import "TMDHTMLTips.h"
#import "../Utilities/TextMate.h" // -positionForWindowUnderCaret

@interface TMDHTMLTipsCommand : TMDCommand
@end

@implementation TMDHTMLTipsCommand
+ (void)load
{
	[TMDCommand registerObject:[self new] forCommand:@"tooltip"];
}

- (NSString *)commandDescription
{
	return @"Shows a tooltip at the caret with the provided content, optionally rendered as HTML.";
}

- (NSString *)usageForInvocation:(NSString *)invocation;
{
	return [NSString stringWithFormat:@"Tooltip content is taken from STDIN, e.g.:\n\n\t%@ --format=html <<< '<some>html</some>'\nUse --transparent (-t) to give the tooltip window a transparent background (10.5+ only)", invocation];
}


static option_t const expectedOptions[] =
{
	{ "t", "transparent", option_t::no_argument, option_t::none, "Gives the tooltip window a transparent background (10.5+ only)."},
	{ "f", "format", option_t::required_argument, option_t::string, "'text' to display the content as-is, or 'html' to render it as HTML. Default is text."},
};

- (void)handleCommand:(CLIProxy*)proxy
{
	NSString* content = nil;
	
	SetOptionTemplate(proxy, expectedOptions);

	if([proxy numberOfArguments] > 3)
	{
		ErrorAndReturn(@"too many arguments");
	}
	else if([proxy argumentAtIndex:2])
	{
		content = [proxy argumentAtIndex:2];
	}
	else
	{
		NSData *data = [[proxy inputHandle] readDataToEndOfFile];

		if([data length] > 0)
			content = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
	}

	if(content == nil || [content length] == 0)
		ErrorAndReturn(@"no content given");

	NSPoint pos = NSZeroPoint;

	if(id textView = [NSApp targetForAction:@selector(positionForWindowUnderCaret)])
		pos = [textView positionForWindowUnderCaret];

	BOOL transparent = [[proxy valueForOption:@"transparent"] boolValue];
	BOOL html = NO;
	if([[proxy valueForOption:@"format"] isEqualToString:@"html"])
		html = YES;
	else if([proxy valueForOption:@"format"] && ![[proxy valueForOption:@"format"] isEqualToString:@"text"])
		ErrorAndReturn(@"invalid format - only html and text are supported");

	[TMDHTMLTip showWithContent:content atLocation:pos transparent:transparent html:html];
}
@end
