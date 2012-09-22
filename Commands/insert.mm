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
	NSDictionary* args = [proxy parameters];
	BOOL success = NO;
	if(NSString* text = [args objectForKey:@"text"])
		success = insert_text(text);
	else if(NSString* snippet = [args objectForKey:@"snippet"])
		success = insert_snippet(snippet);
	if(!success)
		[[proxy errorHandle] writeString:@"1"];
}

- (NSString *)commandDescription
{
	return @"Tries to insert a text or a snippet into the front-most document.\nSTDERR returns on error “1” otherwise nothing.";
}

- (NSString *)usageForInvocation:(NSString *)invocation;
{
	return [NSString stringWithFormat:@"\t%1$@ --text 'This inserts a text.'\n\t%1$@ --snippet 'This ${1:inserts} a ${2:snippet}.'", invocation];
}

@end
