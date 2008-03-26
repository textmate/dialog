#import "../Dialog2.h"
#import "../TMDCommand.h"
#import "Utilities/TextMate.h"

@interface TMDInsertCommands : TMDCommand
@end

@implementation TMDInsertCommands
+ (void)load
{
	[TMDCommand registerObject:[self new] forCommand:@"x-insert"];
}

- (void)handleCommand:(CLIProxy*)proxy;
{
	NSString* text = nil;

	if([proxy numberOfArguments] > 3)
	{
		ErrorAndReturn(@"too many arguments");
	}
	else if([proxy argumentAtIndex:2])
	{
		text = [proxy argumentAtIndex:2];
	}
	else
	{
		NSData *data = [[proxy inputHandle] readDataToEndOfFile];

		if([data length] > 0)
			text = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
	}

	if(text == nil || [text length] == 0)
		ErrorAndReturn(@"no text given");

	[TextMate insertText:text asSnippet:YES];
}
@end