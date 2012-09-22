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
	return [NSString stringWithFormat:@"%@ help [command]", invocation];
}

- (NSString *)commandSummaryText
{
	NSDictionary *commands = [TMDCommand registeredCommands];
	
	NSMutableString *help   = [NSMutableString stringWithCapacity:100];
	NSMutableString *xhelp  = [NSMutableString stringWithCapacity:100];
	NSString *descrIndent   = @"    ";
	NSString *formatString  = [NSString stringWithFormat:@"  %%@\n%@%%@\n", descrIndent];
	NSString *newLineIndent = [NSString stringWithFormat:@"\n%@", descrIndent];

	NSArray *sortedKeys = [[commands allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];

	[help setString:[NSString stringWithFormat:@"%lu commands registered:\n\n", [sortedKeys count]]];

	for(NSString* commandName in sortedKeys)
	{
		NSString *description = [(TMDCommand*)[commands objectForKey:commandName] commandDescription];
		description = [description stringByReplacingOccurrencesOfString:@"\n" withString:newLineIndent];
		if([commandName hasPrefix:@"x-"])
			[xhelp appendFormat:formatString, commandName, description];
		else
			[help appendFormat:formatString, commandName, description];
	}

	[help appendFormat:@"\n  ==== API commands ====\n\n%@", xhelp];
	[help appendString:@"\nUse `\"$DIALOG\" help command` for detailed help\n"];

	return help;
}

- (NSString *)helpForCommand:(NSString *)commandName
{
	NSMutableString *help = [NSMutableString stringWithCapacity:100];
	
	TMDCommand *command = nil;
	if(command = [TMDCommand objectForCommand:commandName])
	{
		if([commandName hasPrefix:@"x-"])
			[help setString:@"==== API command ====\n"];
		[help appendFormat:@"%@\n\n",[command commandDescription]];
		[help appendFormat:@"“%@” usage:\n",commandName];
		[help appendFormat:@"%@\n",[command usageForInvocation:[NSString stringWithFormat:@"\"$DIALOG\" %@", commandName]]];
	}
	else
		[help appendFormat:@"Unknown command “%@”\n", commandName];

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
	
