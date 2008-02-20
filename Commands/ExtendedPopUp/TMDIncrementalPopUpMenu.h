//
//  TMDIncrementalPopUpMenu.h
//
//  Created by Joachim MŒrtensson on 2007-08-10.
//  Copyright (c) 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#define MAX_ROWS 15

@interface TMDIncrementalPopUpMenu : NSWindow
{
	NSArray* suggestions;
	NSMutableString* mutablePrefix;
	NSString* extraChars;
	NSString* staticPrefix;
	NSArray* filtered;
	NSString* shell;
    NSDictionary* extraOptions;
    NSDictionary* env;
	IBOutlet NSTableView* theTableView;
	float stringWidth;
	NSPoint caretPos;
	BOOL isAbove;
	BOOL closeMe;
}
- (id)initWithSuggestions:(NSArray*)theSuggestions currentWord:(NSString*)currentWord staticPrefix:(NSString*)staticPrefix extraChars:(NSString*)extraAllowedChars shellCommand:(NSString*)shellCommand environment:(NSString*)theEnvironment extraOptions:(NSString*)theOptions;
- (void)filter;
- (NSMutableString*)mutablePrefix;
- (id)theTableView;
- (void)keyDown:(NSEvent*)anEvent;
- (void)tab;
- (int)stringWidth;
- (void)writeToTM:(NSString*)aString asSnippet:(BOOL)snippet;
- (NSString*)executeShellCommand:(NSString*)command WithDictionary:(NSDictionary*)dict;
- (NSArray*)filtered;
- (void)setFiltered:(NSArray*)aValue;
- (void)setCaretPos:(NSPoint)aPos;
- (void)setAbove:(BOOL)aBool;
- (void)completeAndInsertSnippet:(id)nothing;
- (BOOL)getCloseStatus;

@end
