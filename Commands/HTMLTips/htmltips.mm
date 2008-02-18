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
	return @"Shows a tooltip at the caret with the provided content rendered as HTML.";
}

- (NSString *)usageForInvocation:(NSString *)invocation;
{
	return [NSString stringWithFormat:@"Tooltip content is taken from STDIN, e.g.:\n\n\t%@ <<< '<some>html</some>'\nUse --transparent (-t) to give the tooltip window a transparent background (10.5+ only)", invocation];
}


static option_t const expectedOptions[] =
{
	{ "t", "transparent", option_t::no_argument, option_t::none, "Gives the tooltip window a transparent background (10.5+ only)."},
};

- (void)handleCommand:(CLIProxy*)interface
{
	NSString* content = nil;
	
	SetOptionTemplate(interface, expectedOptions);

	if([interface numberOfArguments] > 3)
	{
		ErrorAndReturn(@"too many arguments");
	}
	else if([interface argumentAtIndex:2])
	{
		content = [interface argumentAtIndex:2];
	}
	else
	{
		NSData *data = [[interface inputHandle] readDataToEndOfFile];

		if([data length] > 0)
			content = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
	}

	if(content == nil || [content length] == 0)
		ErrorAndReturn(@"no content given");

	NSPoint pos = NSZeroPoint;

	if(id textView = [NSApp targetForAction:@selector(positionForWindowUnderCaret)])
		pos = [textView positionForWindowUnderCaret];

	BOOL transparent = [[interface valueForOption:@"transparent"] boolValue];
	[TMDHTMLTip showWithHTML:content atLocation:pos transparent:transparent];
}
@end
