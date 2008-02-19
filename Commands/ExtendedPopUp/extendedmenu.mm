#import "../../TMDCommand.h"
#import "../../Dialog2.h"
#import "TMDIncrementalPopUpMenu.h"
#import "../Utilities/TextMate.h" // -positionForWindowUnderCaret

/*
echo '{suggestions = ({title = "**law**";filterOn = "law";},{title = "**laws**";filterOn = "laws";snippet = "(${1:hello}, ${2:again})";}); mutablePrefix = ""; currentWord = "la";shell = "ruby -e \"puts STDIN.read\""; }' |"$DIALOG" extended-popup
*/

// ==================
// = Extended Popup =
// ==================
@interface TMDXPopUp : TMDCommand
{
}
@end

@implementation TMDXPopUp
+ (void)load
{
	[TMDCommand registerObject:[self new] forCommand:@"popup"];
}

- (void)handleCommand:(CLIProxy*)proxy
{
	NSDictionary* initialValues = [proxy readPropertyListFromInput];
    
	NSPoint pos = NSZeroPoint;
	if(id textView = [NSApp targetForAction:@selector(positionForWindowUnderCaret)])
		pos = [textView positionForWindowUnderCaret];

	TMDIncrementalPopUpMenu* xPopUp = [[TMDIncrementalPopUpMenu alloc] initWithDictionary:initialValues];
	[xPopUp setCaretPos:pos];
	[xPopUp showWindow:self];
}

@end
