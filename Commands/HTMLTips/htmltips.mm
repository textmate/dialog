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
	return [NSString stringWithFormat:@"Tooltip content is taken from STDIN, e.g.:\n\n\t%@ <<< '<some>html</some>'", invocation];
}

- (void)handleCommand:(CLIProxy*)interface
{
	NSString* content = nil;

	if([[interface arguments] count] > 2)
	{
		content = [[[interface arguments] subarrayWithRange:NSMakeRange(2, [[interface arguments] count] - 2)] componentsJoinedByString:@" "];
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

	[TMDHTMLTip showWithHTML:content atLocation:pos];
}
@end
