#import "../Dialog2.h"
#import "../TMDCommand.h"
#import "../OptionParser.h"

/*
"$DIALOG" help filepanel
*/

// =========
// = TMDFilePanelCommand =
// =========

@interface TMDFilePanelCommand : TMDCommand
{
}
@end

@implementation TMDFilePanelCommand
+ (void)load
{
	[super registerObject:[self new] forCommand:@"filepanel"];
}

- (void)handleCommand:(CLIProxy*)proxy
{
	NSDictionary* args = [proxy parameters];

	id panel = nil;
	if([args objectForKey:@"isSavePanel"])
		panel = (NSSavePanel*)[NSSavePanel savePanel];
	else
		panel = (NSOpenPanel*)[NSOpenPanel openPanel];

	

	if(NSString* title = [args objectForKey:@"title"])
		[panel setTitle:title];
	if(NSString* prompt = [args objectForKey:@"prompt"])
		[panel setPrompt:prompt];
	if(NSString* message = [args objectForKey:@"message"])
		[panel setMessage:message];
	if(NSString* label = [args objectForKey:@"label"])
		[panel setNameFieldLabel:label];
	if(NSString* filename = [args objectForKey:@"filename"])
		[panel setNameFieldStringValue:filename];

	if(NSString* path = [args objectForKey:@"defaultDirectory"])
		if(NSURL *url = [NSURL fileURLWithPath:[path stringByResolvingSymlinksInPath] isDirectory:YES])
			[panel setDirectoryURL:url];

	if([args objectForKey:@"canChooseFiles"])
		[panel setCanChooseFiles:[[args objectForKey:@"canChooseFiles"] boolValue]];
	if([args objectForKey:@"canChooseDirectories"])
		[panel setCanChooseDirectories:[[args objectForKey:@"canChooseDirectories"] boolValue]];
	if([args objectForKey:@"allowsMultipleSelection"])
		[panel setAllowsMultipleSelection:[[args objectForKey:@"allowsMultipleSelection"] boolValue]];
	if([args objectForKey:@"canCreateDirectories"])
		[panel setCanCreateDirectories:[[args objectForKey:@"canCreateDirectories"] boolValue]];
	if([args objectForKey:@"treatsFilePackagesAsDirectories"])
		[panel setTreatsFilePackagesAsDirectories:[[args objectForKey:@"treatsFilePackagesAsDirectories"] boolValue]];
	if([args objectForKey:@"showsHiddenFiles"])
		[panel setShowsHiddenFiles:[[args objectForKey:@"showsHiddenFiles"] boolValue]];

	if(NSString *typesStr = [args objectForKey:@"allowedFileTypes"])
	{
		id raw_types = [NSPropertyListSerialization propertyListFromData:[typesStr dataUsingEncoding:NSUTF8StringEncoding] mutabilityOption:NSPropertyListImmutable format:nil errorDescription:NULL];
		NSArray *types = nil;
		if([raw_types isKindOfClass:[NSString class]])
			types = [NSArray arrayWithObject:raw_types];
		else if([raw_types isKindOfClass:[NSArray class]])
			types = raw_types;
		else
			fprintf(stderr, "no single string or plist array passed as value for option '--allowedFileTypes'\n");
		if(types)
			[panel setAllowedFileTypes:types];
	}

	if([args objectForKey:@"allowsOtherFileTypes"])
		[panel setAllowsOtherFileTypes:[[args objectForKey:@"allowsOtherFileTypes"] boolValue]];

	NSInteger panelResult = [panel runModal];

	NSMutableDictionary* resultDict = [NSMutableDictionary dictionary];
	[resultDict setObject:[NSNumber numberWithInt:panelResult] forKey:@"buttonClicked"];

	if(panelResult)
	{
		if([args objectForKey:@"isSavePanel"])
			[resultDict setObject:[[panel URL] path] forKey:@"path"];
		else
		{
			if([[panel URLs] count] == 1)
				[resultDict setObject:[[panel URL] path] forKey:@"path"];
			else if([[panel URLs] count] > 1)
			{
				NSMutableArray *paths = [NSMutableArray arrayWithCapacity:[[panel URLs] count]];
				for(NSURL* url in [panel URLs])
					[paths addObject:[url path]];
				[resultDict setObject:paths forKey:@"paths"];
			}
		}
	}

	[TMDCommand writePropertyList:resultDict toFileHandle:[proxy outputHandle]];

}

- (NSString *)commandDescription
{
	return @"Shows an open file/folder or save file panel.";
}

- (NSString *)usageForInvocation:(NSString *)invocation;
{
	return [NSString stringWithFormat:
		@"\t%1$@ --title Title --prompt Prompt --message Message --defaultDirectory '~/Desktop' showsHiddenFiles 1\n"
		@"\t%1$@ --isSavePanel --title 'Save Me' --label 'Label:' --filename 'test.txt' --allowedFileTypes '(txt,tab)'\n"
		@"\nOptions:\n"
		@"\t--allowedFileTypes «plist array of allowed file types or a single string»\n"
		@"\t\te.g. --allowedFileTypes pdf\n"
		@"\t\t     --allowedFileTypes '(txt,tab)'\n"
		@"\t--allowsMultipleSelection {1,0} [not in 'isSavePanel' mode]\n"
		@"\t--allowsOtherFileTypes {1,0}\n"
		@"\t--canChooseDirectories {1,0}\n"
		@"\t--canChooseFiles {1,0}\n"
		@"\t--canCreateDirectories {1,0}\n"
		@"\t--defaultDirectory «valid directory path»\n"
		@"\t\tdefault directory for panel, if not passed the last visited one will be used\n"
		@"\t--filename «default file name» [only in 'isSavePanel' mode]\n"
		@"\t--isSavePanel\n"
		@"\t\tif passed shows a save file panel otherwise an open file panel\n"
		@"\t--label «a label» [only in 'isSavePanel' mode]\n"
		@"\t\tdefault 'Save As:'\n"
		@"\t--message «a message»\n"
		@"\t--prompt «a prompt»\n"
		@"\t\taction button title - default 'Open' or 'Save' for isSavePanel mode\n"
		@"\t--showsHiddenFiles {1,0}\n"
		@"\t--title «a title»\n"
		@"\t\twindow title - default 'Open' or 'Save' for isSavePanel mode\n"
		@"\t--treatsFilePackagesAsDirectories {1,0}\n"
			, invocation];
}
@end
