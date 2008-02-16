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

- (void)handleCommand:(NSDictionary *)options
{
	NSString* content = nil;
	NSArray* args     = [options objectForKey:@"arguments"];

	if([args count] > 2)
	{
		content = [[args subarrayWithRange:NSMakeRange(2, [args count] - 2)] componentsJoinedByString:@" "];
	}
	else
	{
		NSFileHandle *stdinFP = (NSFileHandle *)[options objectForKey:@"stdin"];
		NSData *data = [stdinFP readDataToEndOfFile];

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
