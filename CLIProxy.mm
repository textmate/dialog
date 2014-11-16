//
//  CLIProxy.mm
//  Dialog2
//
//  Created by Ciaran Walsh on 16/02/2008.
//

#import "CLIProxy.h"
#import "TMDCommand.h"

@interface CLIProxy ()
{
	NSArray* _arguments;
	NSDictionary* _parameters;
}
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
		_inputHandle      = [NSFileHandle fileHandleForReadingAtPath:[options objectForKey:@"stdin"]];
		_outputHandle     = [NSFileHandle fileHandleForWritingAtPath:[options objectForKey:@"stdout"]];
		_errorHandle      = [NSFileHandle fileHandleForWritingAtPath:[options objectForKey:@"stderr"]];
		_arguments        = [options objectForKey:@"arguments"];
		_environment      = [options objectForKey:@"environment"];
		_workingDirectory = [options objectForKey:@"cwd"];
	}
	return self;
}

- (NSDictionary*)parameters
{
	if(!_parameters)
	{
		NSMutableDictionary* res = [NSMutableDictionary dictionary];
		if(id plist = [TMDCommand readPropertyList:self.inputHandle error:NULL])
		{
			if([plist isKindOfClass:[NSDictionary class]])
				res = plist;
		}

		NSString* lastKey = nil;
		for(NSUInteger i = 2; i < [_arguments count]; ++i)
		{
			NSString* arg = _arguments[i];
			if([arg hasPrefix:@"--"] && ![arg isEqualToString:@"--"])
			{
				lastKey = [arg substringFromIndex:2];
			}
			else if(lastKey)
			{
				if([arg isEqualToString:@"--"])
					res[lastKey] = i+1 < [_arguments count] ? _arguments[++i] : @"";
				else
					res[lastKey] = arg;
				lastKey = nil;
			}
		}
		if(lastKey)
			res[lastKey] = @""; // We use NSString because we may send mutableCopy to parameters

		_parameters = res;
	}
	return _parameters;
}

- (NSUInteger)numberOfArguments;
{
	return [_arguments count];
}

- (NSString*)argumentAtIndex:(NSUInteger)index;
{
	return index < [_arguments count] ? _arguments[index] : nil;
}

// ===================
// = Reading/Writing =
// ===================
- (void)writeStringToOutput:(NSString*)aString;
{
	[self.outputHandle writeData:[aString dataUsingEncoding:NSUTF8StringEncoding]];
}

- (void)writeStringToError:(NSString*)aString;
{
	[self.errorHandle writeData:[aString dataUsingEncoding:NSUTF8StringEncoding]];
}

- (id)readPropertyListFromInput;
{
	NSError* error = nil;
	id plist       = [TMDCommand readPropertyList:self.inputHandle error:&error];

	if(!plist)
		[self writeStringToError:[error localizedDescription] ?: @"unknown error parsing property list\n"];

	return plist;
}
@end
