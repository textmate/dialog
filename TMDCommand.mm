#import "TMDCommand.h"

static NSMutableDictionary* Commands = nil;

@implementation TMDCommand
+ (void)registerObject:(id)anObject forCommand:(NSString*)aCommand
{
	if(!Commands)
		Commands = [NSMutableDictionary new];
	[Commands setObject:anObject forKey:aCommand];
}

+ (NSDictionary *)registeredCommands
{
	return [[Commands copy] autorelease];
}

+ (id)objectForCommand:(NSString*)aCommand
{
	return [Commands objectForKey:aCommand];
}

+ (id)readPropertyList:(NSFileHandle*)aFileHandle error:(NSString**)error;
{
	NSData* data = [aFileHandle readDataToEndOfFile];
	if([data length] == 0)
		return nil;

	id plist = [NSPropertyListSerialization propertyListFromData:data mutabilityOption:NSPropertyListMutableContainersAndLeaves format:nil errorDescription:error];

	return plist;
}

+ (void)writePropertyList:(id)aPlist toFileHandle:(NSFileHandle*)aFileHandle withProxy:(CLIProxy*)proxy
{
	NSString* error = nil;

	if(NSData* data = [NSPropertyListSerialization dataFromPropertyList:aPlist format:NSPropertyListXMLFormat_v1_0 errorDescription:&error])
	{

		// check, if a proxy is passed, for --filter <key> option
		// if so then only return the passed 'key' value as a plain string
		// or for --filter '(array,of,keys)' then return the values of these keys
		// separated by a new line \n
		if(proxy)
		{
			NSDictionary *args = [proxy parameters];
			if(NSString *outputKeys = [args objectForKey:@"filter"])
			{
				// check argument and try to convert it to an array
				id raw_keys = [NSPropertyListSerialization propertyListFromData:[(NSString*)outputKeys dataUsingEncoding:NSUTF8StringEncoding] mutabilityOption:NSPropertyListImmutable format:nil errorDescription:NULL];
				NSArray *keys = nil;
				if([raw_keys isKindOfClass:[NSString class]])
					keys = [NSArray arrayWithObject:raw_keys];
				else if([raw_keys isKindOfClass:[NSArray class]])
					keys = raw_keys;
				else
				{
					fprintf(stderr, "no single string or array passed as value for option '--filter'\n");
					return;
				}
				NSMutableArray *out = [NSMutableArray arrayWithCapacity:[keys count]];
				for(NSString *outputKey in keys)
				{
					if(NSString *output = [aPlist objectForKey:outputKey])
					{
						[out addObject:output];
					}
					else
					{
						[out addObject:@""];
						fprintf(stderr, "no key '%s' found in returned property list\n", [outputKey UTF8String]);
					}
				}
				[aFileHandle writeString:[out componentsJoinedByString:@"\n"]];
				return;
			}
		}
		[aFileHandle writeData:data];
	}
	else
	{
		fprintf(stderr, "%s\n", [error UTF8String] ?: "unknown error serializing returned property list");
		fprintf(stderr, "%s\n", [[aPlist description] UTF8String]);
	}
}

- (NSString *)commandDescription
{
	return @"No information available for this command";
}

- (NSString *)usageForInvocation:(NSString *)invocation;
{
	return @"No usage information available for this command";
}
@end

@implementation NSFileHandle (WriteString)
- (void)writeString:(NSString *)string;
{
	[self writeData:[string dataUsingEncoding:NSUTF8StringEncoding]];
}
@end