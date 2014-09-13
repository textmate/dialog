//
//  CLIProxy.mm
//  Dialog2
//
//  Created by Ciaran Walsh on 16/02/2008.
//

#import "CLIProxy.h"
#import "TMDCommand.h"

@interface CLIProxy ()
- (NSArray*)arguments;
@end

@implementation CLIProxy
+ (instancetype)proxyWithOptions:(NSDictionary*)options;
{
	return [[CLIProxy alloc] initWithOptions:options];
}

- (instancetype)initWithOptions:(NSDictionary*)options
{
	if(self = [super init])
	{
		inputHandle      = [NSFileHandle fileHandleForReadingAtPath:[options objectForKey:@"stdin"]];
		outputHandle     = [NSFileHandle fileHandleForWritingAtPath:[options objectForKey:@"stdout"]];
		errorHandle      = [NSFileHandle fileHandleForWritingAtPath:[options objectForKey:@"stderr"]];
		arguments        = [options objectForKey:@"arguments"];
		environment      = [options objectForKey:@"environment"];
		workingDirectory = [options objectForKey:@"cwd"];
	}
	return self;
}

- (NSDictionary*)parameters
{
	if(!parameters)
	{
		NSMutableDictionary* res = [NSMutableDictionary dictionary];
		if(id plist = [TMDCommand readPropertyList:[self inputHandle] error:NULL])
		{
			if([plist isKindOfClass:[NSDictionary class]])
				res = plist;
		}

		NSString* lastKey = nil;
		for(NSUInteger i = 2; i < [arguments count]; ++i)
		{
			NSString* arg = [arguments objectAtIndex:i];
			BOOL isOption = [arg hasPrefix:@"--"];
			if(lastKey)
				[res setObject:(isOption ? [NSNull null] : arg) forKey:lastKey];
			lastKey = isOption ? [arg substringFromIndex:2] : nil;
		}

		if(lastKey)
			[res setObject:[NSNull null] forKey:lastKey];

		parameters = res;
	}
	return parameters;
}

- (NSString*)workingDirectory
{
	return workingDirectory;
}

- (NSDictionary*)environment
{
	return environment;
}

- (NSArray*)arguments
{
	if(!parsedOptions)
		return arguments;
	return [parsedOptions objectForKey:@"literals"];
}

- (NSUInteger)numberOfArguments;
{
	return [[self arguments] count];
}

- (NSString*)argumentAtIndex:(NSUInteger)index;
{
	id argument = nil;
	if([[self arguments] count] > index)
		argument = [[self arguments] objectAtIndex:index];
	return argument;
}

- (id)valueForOption:(NSString*)option;
{
	if(!parsedOptions)
	{
		NSLog(@"Error: -valueForOption: called without first setting an option template");
		return nil;
	}
	return [[parsedOptions objectForKey:@"options"] objectForKey:option];
}

- (void)parseOptions
{
	parsedOptions = ParseOptions([self arguments], optionTemplate, optionCount);
}

- (void)setOptionTemplate:(option_t const*)options count:(size_t)count;
{
	optionTemplate = options;
	optionCount = count;
	[self parseOptions];
}

// ===================
// = Reading/Writing =
// ===================
- (void)writeStringToOutput:(NSString*)text;
{
	[[self outputHandle] writeString:text];
}

- (void)writeStringToError:(NSString*)text;
{
	[[self errorHandle] writeString:text];
}

- (id)readPropertyListFromInput;
{
	NSError* error = nil;
	id plist       = [TMDCommand readPropertyList:[self inputHandle] error:&error];

	if(!plist)
		[self writeStringToError:[error localizedDescription] ?: @"unknown error parsing property list\n"];

	return plist;
}

// ================
// = File handles =
// ================
- (NSFileHandle*)inputHandle;
{
	return inputHandle;
}

- (NSFileHandle*)outputHandle;
{
	return outputHandle;
}

- (NSFileHandle*)errorHandle;
{
	return errorHandle;
}
@end
