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

	NSRect mainScreen = [[NSScreen mainScreen] frame];
	enumerate([NSScreen screens], NSScreen* candidate)
	{
		if(NSMinX([candidate frame]) == 0.0f && NSMinY([candidate frame]) == 0.0f)
			mainScreen = [candidate frame];
	}

	pos = NSMakePoint(pos.x,  pos.y);
	TMDIncrementalPopUpMenu* xPopUp = [[TMDIncrementalPopUpMenu alloc] initWithDictionary:initialValues];
	[xPopUp setCaretPos:pos];
	[xPopUp setMainScreen:mainScreen];
	[xPopUp setAbove:NO];

	int offx = (pos.x/mainScreen.size.width) + 1;
	if((pos.x + [[xPopUp window] frame].size.width) > (mainScreen.size.width*offx))
		pos.x = pos.x - [[xPopUp window] frame].size.width;
	pos.x = pos.x - [xPopUp stringWidth];

	if(pos.y>=0 && pos.y<[[xPopUp window] frame].size.height)
	{
		pos.y = pos.y + ([[xPopUp window] frame].size.height + [[NSUserDefaults standardUserDefaults] integerForKey:@"OakTextViewNormalFontSize"]*1.5);
		[xPopUp setAbove:YES];
	}
	if(pos.y<0 && (mainScreen.size.height-[[xPopUp window] frame].size.height)<(pos.y*-1))
	{
		pos.y = pos.y + ([[xPopUp window] frame].size.height + [[NSUserDefaults standardUserDefaults] integerForKey:@"OakTextViewNormalFontSize"]*1.5);
		[xPopUp setAbove:YES];
	}
	[[xPopUp window] setFrameTopLeftPoint:pos];
	[xPopUp showWindow:self];
}

@end
