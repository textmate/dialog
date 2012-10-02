#import "../TMDCommand.h"

// ========
// = Help =
// ========

@interface TMDHelpCommand : TMDCommand
{
}
@end

@implementation TMDHelpCommand
+ (void)load
{
	[TMDCommand registerObject:[self new] forCommand:@"help"];
}

- (NSString *)commandDescription
{
	return @"Gives a brief list of available commands, or usage details for a specific command.";
}

- (NSString *)usageForInvocation:(NSString *)invocation;
{
	return [NSString stringWithFormat:@"\t%1$@ [«command»]\n", invocation];
}

- (NSString *)commandSummaryText
{
	NSDictionary *commands = [TMDCommand registeredCommands];
	NSArray *sortedItems   = [[commands allKeys] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];

	NSMutableString *help = [NSMutableString stringWithCapacity:100];

	NSInteger commandCount = 0;
	for(NSString *commandName in sortedItems)
	{
		if(![commandName hasPrefix:@"x-"])
		{
			++commandCount;
			NSString *description = [[(TMDCommand*)[commands objectForKey:commandName] commandDescription] 
												stringByReplacingOccurrencesOfString:@"\n" withString:@"\n\t\t"];
			[help appendFormat:@"\t%@\n\t\t%@\n", commandName, description];
		}
	}
	[help insertString:[NSString stringWithFormat:@"%ld commands registered:\n", commandCount] atIndex:0];

	[help appendString:@"\nUse `\"$DIALOG\" help command` for detailed help\n\n"];
	[help appendString:
		@"Options:\n"
		@"\t--filter <key>\n"
		@"\t--filter <plist array of keys>\n"
		@"\t\tFor commands returning a property list as default specify the <key(s)>\n"
		@"\t\twhose value(s) should be outputted as plain string\n"
		@"\t\tseparated by a new line character.\n"
		@"\t\tIf a passed <key> doesn't exist it returns an empty string.\n"];

	return help;
}

- (NSString *)helpForCommand:(NSString *)commandName
{
	NSMutableString *help = [NSMutableString stringWithCapacity:100];
	
	TMDCommand *command = nil;
	if(![commandName hasPrefix:@"x-"] && (command = [TMDCommand objectForCommand:commandName]))
	{
		[help appendFormat:@"%@\n\n",[command commandDescription]];
		[help appendFormat:@"'%@' usage:\n",commandName];
		[help appendFormat:@"%@\n",[command usageForInvocation:[NSString stringWithFormat:@"\"$DIALOG\" %@", commandName]]];
	}
	else
		[help appendFormat:@"Unknown command '%@'\n", commandName];

	return help;
}

- (void)handleCommand:(CLIProxy*)proxy
{
	NSString *text = @"";
	
	if([proxy numberOfArguments] < 3)
		text = [self commandSummaryText];
	else
		text = [self helpForCommand:[proxy argumentAtIndex:2]];

	[proxy writeStringToError:text];
}
@end
/*
"$DIALOG" help
"$DIALOG" help help
*/