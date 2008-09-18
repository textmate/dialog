//
//  TMDIncrementalPopUpMenu.h
//
//  Created by Joachim Mårtensson on 2007-08-10.
//

#import <Cocoa/Cocoa.h>
#import "CLIProxy.h"

#define MAX_ROWS 15

@interface TMDIncrementalPopUpMenu : NSWindow
{
	NSFileHandle* outputHandle;
	NSArray* suggestions;
	NSMutableDictionary* images;
	NSMutableString* mutablePrefix;
	NSString* staticPrefix;
	NSArray* filtered;
	NSTableView* theTableView;
	NSPoint caretPos;
	BOOL isAbove;
	BOOL closeMe;
	BOOL caseSensitive;

	NSMutableCharacterSet* textualInputCharacters;	
}
- (id)initWithProxy:(CLIProxy*)proxy;
- (void)setCaretPos:(NSPoint)aPos;
@end
