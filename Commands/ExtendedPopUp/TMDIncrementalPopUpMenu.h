//
//  TMDIncrementalPopUpMenu.h
//
//  Created by Joachim MŒrtensson on 2007-08-10.
//

#import <Cocoa/Cocoa.h>
#import "CLIProxy.h"

#define MAX_ROWS 15

@interface TMDIncrementalPopUpMenu : NSWindow
{
	NSArray* suggestions;
	NSMutableDictionary* images;
	NSMutableString* mutablePrefix;
	NSString* extraChars;
	NSString* staticPrefix;
	NSArray* filtered;
	NSString* shell;
	NSDictionary* extraOptions;
	NSDictionary* env;
	NSTableView* theTableView;
	float stringWidth;
	NSPoint caretPos;
	BOOL isAbove;
	BOOL closeMe;
	BOOL caseSensitive;
}
- (id)initWithProxy:(CLIProxy*)proxy;
- (void)filter;
- (NSMutableString*)mutablePrefix;
- (id)theTableView;
- (void)keyDown:(NSEvent*)anEvent;
- (void)tab;
- (int)stringWidth;
- (NSString*)executeShellCommand:(NSString*)command WithDictionary:(NSDictionary*)dict;
- (NSArray*)filtered;
- (void)setFiltered:(NSArray*)aValue;
- (void)setCaretPos:(NSPoint)aPos;
- (void)setAbove:(BOOL)aBool;
- (void)completeAndInsertSnippet:(id)nothing;
- (BOOL)getCloseStatus;

@end
