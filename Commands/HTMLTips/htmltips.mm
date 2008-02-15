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
	[TMDCommand registerObject:[self new] forCommand:@"html-tip"];
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
	NSFileHandle *stdinFP = (NSFileHandle *)[options objectForKey:@"stdin"];
	NSData *data = [stdinFP readDataToEndOfFile];

	if([data length] == 0)
		return;

	NSString *content = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
	{
		NSPoint pos = NSZeroPoint;

		if(id textView = [NSApp targetForAction:@selector(positionForWindowUnderCaret)])
			pos = [textView positionForWindowUnderCaret];

		[TMDHTMLTip showWithHTML:content atLocation:pos forScreen:[NSScreen mainScreen]];
	}
	[content release];
}
@end
