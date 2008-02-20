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


static option_t const expectedOptions[] =
{
	{ "c", "current-word",	option_t::required_argument, option_t::string, "Sets the current word, which will be used to filter the suggestions."},
	{ "s", "static-prefix",	option_t::required_argument, option_t::string, "A prefix which is used when filtering suggestions."},
	{ "x", "extra-chars",	option_t::required_argument, option_t::string, "A string of extra characters which are allowed while typing."},
	{ "x", "shell-cmd",		option_t::required_argument, option_t::string, "When the user selects an item, this command will be passed the selection on STDIN, and the output will be written to the document."},
};

- (void)handleCommand:(CLIProxy*)proxy
{
	// SetOptionTemplate(proxy, expectedOptions);

	NSDictionary* initialValues = [proxy readPropertyListFromInput];
	NSArray* suggestions = [initialValues objectForKey:@"suggestions"];

	NSPoint pos = NSZeroPoint;
	if(id textView = [NSApp targetForAction:@selector(positionForWindowUnderCaret)])
		pos = [textView positionForWindowUnderCaret];

	TMDIncrementalPopUpMenu* xPopUp = [[TMDIncrementalPopUpMenu alloc] initWithSuggestions:suggestions
                                                                              currentWord:[initialValues objectForKey:@"currentWord"]
                                                                             staticPrefix:[initialValues objectForKey:@"staticPrefix"]
                                                                               extraChars:[initialValues objectForKey:@"extraChars"]
                                                                             shellCommand:[initialValues objectForKey:@"shell"]
	];

	// TMDIncrementalPopUpMenu* xPopUp = [[TMDIncrementalPopUpMenu alloc] initWithSuggestions:suggestions
	//                                                                               currentWord:[proxy valueForOption:@"current-word"]
	//                                                                              staticPrefix:[proxy valueForOption:@"static-prefix"]
	//                                                                                extraChars:[proxy valueForOption:@"extra-chars"]
	//                                                                              shellCommand:[proxy valueForOption:@"shell-cmd"]
	// ];
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
		@"%@ «options» <<<'( { title = \"foo\" }, { title = \"bar\" } )'\n"
		@"\nOptions:\n%@",
		invocation, GetOptionList(expectedOptions)];
}

@end
