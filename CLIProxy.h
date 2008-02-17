//
//  CLIProxy.h
//  Dialog2
//
//  Created by Ciaran Walsh on 16/02/2008.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "OptionParser.h"

@interface CLIProxy : NSObject
{
	NSArray* 		arguments;
	NSDictionary* 	environment;
	NSString* 		workingDirectory;

	NSFileHandle* inputHandle;
	NSFileHandle* outputHandle;
	NSFileHandle* errorHandle;
}
+ (id)interfaceWithOptions:(NSDictionary*)options;
- (id)initWithOptions:(NSDictionary*)options;

- (void)writeStringToOutput:(NSString*)text;
- (void)writeStringToError:(NSString*)text;
- (id)readPropertyListFromInput;

- (NSFileHandle*)inputHandle;
- (NSFileHandle*)outputHandle;
- (NSFileHandle*)errorHandle;

- (NSDictionary*)environment;

- (NSString*)workingDirectory;

- (NSArray*)arguments;
- (NSDictionary*)parseOptionsWithExpectedOptions:(option_t const*)expectedOptions;
@end
