#import "../Dialog2.h"
#import "../TMDCommand.h"
#import "../OptionParser.h"

/*
echo '{alertStyle = warning; button1 = 'OK'; title = 'test'; body = 'Testing';}' | "$DIALOG" alert

"$DIALOG" help alert
"$DIALOG" alert --alertStyle critical --title "FOOL!" --body "test" --button1 foo --button2 bar --button3 baz
*/

// =========
// = Alert =
// =========

@interface TMDAlertCommand : TMDCommand
{
}
@end

NSAlertStyle alert_style_from_string (NSString* str)
{
	if([str isEqualToString:@"warning"])
		return NSWarningAlertStyle;
	else if([str isEqualToString:@"critical"])
		return NSCriticalAlertStyle;
	else
		return NSInformationalAlertStyle;
}

@implementation TMDAlertCommand
+ (void)load
{
	[super registerObject:[self new] forCommand:@"alert"];
}

- (void)handleCommand:(CLIProxy*)proxy
{
	NSDictionary* args = [proxy parameters];

	NSAlert *alert = [[[NSAlert alloc] init] autorelease];
	[alert setAlertStyle:alert_style_from_string([args objectForKey:@"alertStyle"])];
	if(NSString* msg = [args objectForKey:@"title"])
		[alert setMessageText:msg];
	if(NSString* txt = [args objectForKey:@"body"])
		[alert setInformativeText:txt];
	if(NSString* sup = [args objectForKey:@"suppression"])
	{
		[alert setShowsSuppressionButton:YES];
		[[alert suppressionButton] setTitle:sup];
	}

	if(NSString* iconPath = [args objectForKey:@"icon"])
	{
		NSImage *icon = nil;
		iconPath = [iconPath stringByResolvingSymlinksInPath];
		BOOL isDir = NO;
		if([[NSFileManager defaultManager] fileExistsAtPath:iconPath isDirectory:&isDir] && !isDir)
		{
			icon = [[NSImage alloc] initByReferencingFile:iconPath];
			if(icon && [icon isValid])
			{
				[alert setIcon:icon];
				[icon release];
			}
		}
		else if(icon = [NSImage imageNamed:iconPath])
			[alert setIcon:icon];
		else if(icon = [NSImage imageNamed:[iconPath stringByReplacingOccurrencesOfString:@"ImageName" withString:@""]])
			[alert setIcon:icon];

		if(!icon)
			fprintf(stderr, "Passed icon path or named image '%s' not found.\n", [iconPath UTF8String]);

	}

	int i = 0;
	while(NSString* button = [args objectForKey:[NSString stringWithFormat:@"button%d", ++i]])
		[alert addButtonWithTitle:button];

	int alertResult = ([alert runModal] - NSAlertFirstButtonReturn);
	NSMutableDictionary* resultDict = [NSMutableDictionary dictionary];
	[resultDict setObject:[NSNumber numberWithInt:alertResult] forKey:@"buttonClicked"];
	if([args objectForKey:@"suppression"])
		[resultDict setObject:[NSNumber numberWithInt:[[alert suppressionButton] state]] forKey:@"suppressionButtonState"];

	[TMDCommand writePropertyList:resultDict toFileHandle:[proxy outputHandle] withProxy:proxy];
}

- (NSString *)commandDescription
{
	return @"Shows a customizable alert box and returns the index of the chosen button - counting from the right.";
}

- (NSString *)usageForInvocation:(NSString *)invocation;
{
	return [NSString stringWithFormat:
	@"\t%1$@ --alertStyle critical --title 'Delete File?' --body 'You cannot undo this action.' --button1 Delete --button2 Cancel\n"
	@"\t%1$@ --filter buttonClicked --title 'Delete File?' --body 'You cannot undo this action.' --button1 Delete --button2 Cancel\n"
	@"\t%1$@ --icon NSUserAccounts --title 'Delete Account?' --body 'You cannot undo this action.' --button1 Delete --button2 Cancel\n"
	@"\t%1$@ --icon '~/Pictures/iChat Icons/Flags/Denmark.png' --title 'First Run?' --body 'Please note this.' --suppression 'Do not show this again'\n"
	@"\nOption:\n"
	@"\t--alertStyle {informational, warning, critical}\n"
	@"\t\t if not specified the default style is 'informational'\n"
	@"\t--icon «image path or known image name»\n"
	@"\t--suppression «title»\n", invocation];
}
@end
