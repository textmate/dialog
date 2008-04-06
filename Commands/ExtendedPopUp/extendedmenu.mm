#import "../../TMDCommand.h"
#import "../../Dialog2.h"
#import "TMDIncrementalPopUpMenu.h"
#import "../Utilities/TextMate.h" // -positionForWindowUnderCaret

/*
echo '{suggestions = ({title = "**law**";filterOn = "law";},{title = "**laws**";filterOn = "laws";snippet = "(${1:hello}, ${2:again})";}); mutablePrefix = ""; currentWord = "la";shell = "ruby -e \"puts STDIN.read\""; }' |"$DIALOG" popup
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

static option_t const expectedOptions[] =
{
	{ "f", "initial-filter",	option_t::required_argument, option_t::string,	"Sets the text which will be used for initial filtering of the suggestions."},
	{ "s", "static-prefix",		option_t::required_argument, option_t::string,	"A prefix which is used when filtering suggestions."},
	{ "e", "extra-chars",		option_t::required_argument, option_t::string,	"A string of extra characters which are allowed while typing."},
	{ "i", "case-insensitive",	option_t::no_argument, option_t::none,				"Case is ignored when comparing typed characters."},
	{ "x", "shell-cmd",			option_t::required_argument, option_t::string,	"When the user selects an item, this command will be passed the selection on STDIN, and the output will be written to the document."},
	{ "w", "wait",					option_t::no_argument, option_t::none,				"Causes the command to not return until the user has selected an item (or cancelled)."},
};


- (void)handleCommand:(CLIProxy*)proxy
{
	SetOptionTemplate(proxy, expectedOptions);

	NSPoint pos = NSZeroPoint;
	if(id textView = [NSApp targetForAction:@selector(positionForWindowUnderCaret)])
		pos = [textView positionForWindowUnderCaret];

	TMDIncrementalPopUpMenu* xPopUp = [[TMDIncrementalPopUpMenu alloc] initWithProxy:proxy];

	[xPopUp setCaretPos:pos];
	[xPopUp orderFront:self];
}

- (NSString *)commandDescription
{
	return @"Presents the user with a list of items which can be filtered down by typing to select the item they want.";
}

- (NSString *)usageForInvocation:(NSString *)invocation;
{
	return [NSString stringWithFormat:
		@"%@ «options» <<<'{ suggestions = ( { title = \"foo\"; }, { title = \"bar\"; } ); }'\n"
		@"\nOptions:\n%@",
		invocation, GetOptionList(expectedOptions)];
}

@end
