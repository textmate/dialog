//
//  CLIProxy.h
//  Dialog2
//
//  Created by Ciaran Walsh on 16/02/2008.
//

#import "OptionParser.h"

@interface CLIProxy : NSObject
@property (nonatomic, readonly) NSFileHandle* inputHandle;
@property (nonatomic, readonly) NSFileHandle* outputHandle;
@property (nonatomic, readonly) NSFileHandle* errorHandle;
@property (nonatomic, readonly) NSDictionary* parameters;
@property (nonatomic, readonly) NSDictionary* environment;
@property (nonatomic, readonly) NSString* workingDirectory;

+ (instancetype)proxyWithOptions:(NSDictionary*)options;
- (instancetype)initWithOptions:(NSDictionary*)options;

- (void)writeStringToOutput:(NSString*)aString;
- (void)writeStringToError:(NSString*)aString;
- (id)readPropertyListFromInput;

- (NSString*)argumentAtIndex:(NSUInteger)index;
- (NSUInteger)numberOfArguments;

- (id)valueForOption:(NSString*)option;
- (void)setOptionTemplate:(option_t const*)options count:(size_t)count;
@end

template <size_t optionCount> void SetOptionTemplate (CLIProxy* proxy, option_t const (&options)[optionCount])
{
	[proxy setOptionTemplate:options count:optionCount];
}
