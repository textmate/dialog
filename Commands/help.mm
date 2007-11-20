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
	return @"Gives a brief list of available commands";
}

- (void)handleCommand:(id)options
{
	NSFileHandle* fh = [options objectForKey:@"stderr"];
	NSDictionary *commands = [TMDCommand registeredCommands];
	
	NSMutableString *help = [NSMutableString stringWithCapacity:100];
	[help appendFormat:@"%d commands registered:\n", [commands count]];

	NSEnumerator *enumerator = [commands keyEnumerator];
	while (NSString *commandName = [enumerator nextObject]) {
		TMDCommand *command = [commands objectForKey:commandName];
		NSString *description = [command commandDescription];
		[help appendFormat:@"\t%@: %@\n", commandName, description];
	}

	// [fh writeData:[@"Help is not yet implemented.\n" dataUsingEncoding:NSUTF8StringEncoding]];
	[fh writeData:[help dataUsingEncoding:NSUTF8StringEncoding]];
}
@end
/*
"$DIALOG" help
*/