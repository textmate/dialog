//
//  CLIProxy.mm
//  Dialog2
//
//  Created by Ciaran Walsh on 16/02/2008.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "CLIProxy.h"
#import "TMDCommand.h"

@implementation CLIProxy
+ (id)interfaceWithOptions:(NSDictionary*)options;
{
	return [[[[self class] alloc] initWithOptions:options] autorelease];
}

- (id)initWithOptions:(NSDictionary*)options
{
	if(self = [super init])
	{
		inputHandle      = [[NSFileHandle fileHandleForReadingAtPath:[options objectForKey:@"stdin"]] retain];
		outputHandle     = [[NSFileHandle fileHandleForWritingAtPath:[options objectForKey:@"stdout"]] retain];
		errorHandle      = [[NSFileHandle fileHandleForWritingAtPath:[options objectForKey:@"stderr"]] retain];
		arguments        = [[options objectForKey:@"arguments"] retain];
		environment      = [[options objectForKey:@"environment"] retain];
		workingDirectory = [[options objectForKey:@"cwd"] retain];
	}
	return self;
}

- (void)dealloc
{
	[inputHandle release];
	[outputHandle release];
	[errorHandle release];
	[arguments release];
	[environment release];
	[workingDirectory release];
	[super dealloc];
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
	return arguments;
}

- (NSDictionary*)parseOptionsWithExpectedOptions:(option_t const*)expectedOptions;
{
	return ParseOptions([self arguments], expectedOptions, sizeof(expectedOptions) / sizeof(typeof(expectedOptions)));
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
	return [TMDCommand readPropertyList:[self inputHandle]];
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
