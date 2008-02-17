#import "../Dialog2.h"
#import "../TMDCommand.h"
#import "../OptionParser.h"

/*
echo '{alertStyle = warning; buttonTitles = ('OK'); messageTitle = 'test'; informativeText = 'Testing';}' | "$DIALOG" alert

"$DIALOG" help alert
"$DIALOG" alert -s critical -m "FOOL!" -t "test" -1 foo -2 bar -3 baz
*/

// =========
// = Alert =
// =========

@interface TMDAlertCommand : TMDCommand
{
}
@end

@implementation TMDAlertCommand
+ (void)load
{
	[super registerObject:[self new] forCommand:@"alert"];
}

static option_t const expectedOptions[] =
{
	{ "m", "message",			option_t::required_argument,	option_t::string,		"Message title."},
	{ "t", "text",				option_t::required_argument,	option_t::string,		"Informative text for the alert."},
	{ "s", "alert-style",	option_t::required_argument,	option_t::string,		"One of warning, critical or informational (the default)."},
	{ "1", "button1",			option_t::required_argument,	option_t::string,		"Button 1 label."},
	{ "2", "button2",			option_t::required_argument,	option_t::string,		"Button 2 label."},
	{ "3", "button3",			option_t::required_argument,	option_t::string,		"Button 3 label."},
};

- (void)handleCommand:(CLIProxy*)interface
{
	// NSFileHandle* fh = [options objectForKey:@"stderr"];

#if 1
	NSDictionary	*parameters       = [[interface parseOptionsWithExpectedOptions:expectedOptions] objectForKey:@"options"];
	NSAlertStyle	alertStyle        = NSInformationalAlertStyle;
	NSString			*alertStyleString = [parameters objectForKey:@"alert-style"];
	NSDictionary	*resultDict       = nil;
		
	NSAlert *alert = [[[NSAlert alloc] init] autorelease];
	
	if([alertStyleString isEqualToString:@"warning"])
	{
		alertStyle = NSWarningAlertStyle;
	}
	else if([alertStyleString isEqualToString:@"critical"])
	{
		alertStyle = NSCriticalAlertStyle;
	}
	else if([alertStyleString isEqualToString:@"informational"])
	{
		alertStyle = NSInformationalAlertStyle;
	}
	
	[alert setAlertStyle:alertStyle];
	if([parameters objectForKey:@"message"])
		[alert setMessageText:[parameters objectForKey:@"message"]];
	if([parameters objectForKey:@"text"])
		[alert setInformativeText:[parameters objectForKey:@"text"]];
	
	// Setup buttons
	if ([parameters objectForKey:@"button1"])
		[alert addButtonWithTitle:[parameters objectForKey:@"button1"]];
	if ([parameters objectForKey:@"button2"])
		[alert addButtonWithTitle:[parameters objectForKey:@"button2"]];
	if ([parameters objectForKey:@"button3"])
		[alert addButtonWithTitle:[parameters objectForKey:@"button3"]];
	
	BOOL modal = YES;
	
	// Show the alert
	if(not modal)
	{
#if 1
		// Not supported yet; needs same infrastructure as will be required for nib-based sheets.
		[NSException raise:@"NotSupportedYet" format:@"Sheet alerts not yet supported."];
#else
		// Window-modal (sheet).NSWindowController
		// Find the window corresponding to the given path

		NSArray* windows = [NSApp windows];
		NSWindow* chosenWindow = nil;
		
		enumerate(windows, NSWindow * window)
		{
			OakDocumentController*	documentController = [window controller];
			if([documentController isKindOfClass:[OakDocumentController class]])
			{
				if(filePath == nil)
				{
					// Take first visible document window
					if( [window isVisible] )
					{
						chosenWindow = window;
						break;
					}
				}
				else
				{
					// Find given document window
					// TODO: documentWithContentsOfFile may be a better way to do this
					// FIXME: standardize paths
					if([[documentController->textDocument filename] isEqualToString:filePath])
					{
						chosenWindow = window;
						break;
					}
				}
			}
		}
		
		// Fall back to modal
		if(chosenWindow == nil)
		{
			modal = YES;
		}
#endif
	}
	
	if(modal)
	{
		int alertResult = ([alert runModal] - NSAlertFirstButtonReturn);
		
		resultDict = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:alertResult] forKey:@"buttonClicked"];
	}

	[TMDCommand writePropertyList:resultDict toFileHandle:[interface outputHandle]];
#endif
}

- (NSString *)commandDescription
{
	return @"Show an alert box.";
}

- (NSString *)usageForInvocation:(NSString *)invocation;
{
	return [NSString stringWithFormat:@"%@ «options»\n\nOptions:\n%@", invocation, GetOptionList(expectedOptions)];
}
@end
