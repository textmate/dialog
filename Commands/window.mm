#import <vector>
#import <string>
#import <sys/stat.h>
#import "../Dialog2.h"
#import "../TMDCommand.h"
#import "../OptionParser.h"
#import "Utilities/TMDChameleon.h"
#import "Utilities/TMDNibController.h"

// ==========
// = Window =
// ==========

@interface TMDWindowCommand : TMDCommand
{
}
@end

// ===================
// = Command handler =
// ===================

std::string find_nib (std::string nibName, std::string currentDirectory)
{
	std::vector<std::string> candidates;

	if(nibName.find(".nib") == std::string::npos)
		nibName += ".nib";

	if(nibName.size() && nibName[0] != '/') // relative path
	{
		candidates.push_back(currentDirectory + "/" + nibName);

		if(char const* bundleSupport = getenv("TM_BUNDLE_SUPPORT"))
			candidates.push_back(bundleSupport + std::string("/nibs/") + nibName);

		if(char const* supportPath = getenv("TM_SUPPORT_PATH"))
			candidates.push_back(supportPath + std::string("/nibs/") + nibName);
	}
	else
	{
		candidates.push_back(nibName);
	}

	iterate(it, candidates)
	{
		fprintf(stderr, "candidate: %s\n", it->c_str());
		struct stat sb;
		if(stat(it->c_str(), &sb) == 0)
			return *it;
	}

	fprintf(stderr, "nib could not be loaded: %s (does not exist)\n", nibName.c_str());
	return "";
}

@implementation TMDWindowCommand
+ (void)load
{
	[super registerObject:[self new] forCommand:@"window"];
}

/*
"$DIALOG" -cmp '{title = "title"; prompt = "prompt"; }' "RequestString"

"$DIALOG" window show -cmp '{title = "title"; prompt = "prompt"; }' "RequestString"
"$DIALOG" window create -cp '{title = "title"; prompt = "prompt"; }' "RequestString"
"$DIALOG" window close 5
echo '{title = "updated title"; prompt = "updated prompt"; }' | "$DIALOG" window update 4

"$DIALOG" window show "/Library/Application Support/TextMate/Bundles/SQL.tmbundle/Support/nibs/connections.nib" -q -d"{'SQL Connections' = ( { title = untitled; serverType = MySQL; hostName = localhost; userName = '$LOGNAME'; } ); }" -n"{ SQL_New_Connection = { title = untitled; serverType = MySQL; hostName = localhost; userName = '$LOGNAME'; }; }" -p'{}' &
*/

- (void)handleCommand:(id)options
{
	NSArray* args = [options objectForKey:@"arguments"];

	static option_t const expectedOptions[] =
	{
		{ "c", "center",		option_t::no_argument										},
		{ "d", "defaults",	option_t::required_argument, option_t::plist			},
		{ "m", "modal",		option_t::no_argument										},
		{ "n", "new-items",	option_t::required_argument, option_t::plist			},
		{ "p", "parameters",	option_t::required_argument, option_t::plist			},
		{ "q", "quiet",		option_t::no_argument										},
	};

	NSDictionary* res = ParseOptions(args, expectedOptions);

	NSString* command = [args objectAtIndex:2];
	if([command isEqualToString:@"create"] || [command isEqualToString:@"show"])
	{
		char const* nibName = [[args lastObject] UTF8String];
		char const* nibPath = [[options objectForKey:@"cwd"] UTF8String];
		NSString* nib = [NSString stringWithUTF8String:find_nib(nibName ?: "", nibPath ?: "").c_str()];

		id dynamicClasses = [[res objectForKey:@"options"] objectForKey:@"new-items"];
		enumerate([dynamicClasses allKeys], id key)
			[TMDChameleon createSubclassNamed:key withValues:[dynamicClasses objectForKey:key]];

		TMDNibController* nibController = [[[TMDNibController alloc] initWithNibName:nib] autorelease];
		NSDictionary *windowOptions = [res objectForKey:@"options"];
		[nibController setParameters:[windowOptions objectForKey:@"parameters"]];
		[Nibs setObject:nibController forKey:[nibController token]];

		NSFileHandle* fh = [options objectForKey:@"stdout"];
		if([command isEqualToString:@"show"])
		{
			[nibController notifyFileHandle:fh];
			[nibController setAutoCloses:YES];
		}
		else
		{
			[fh writeData:[[nibController token] dataUsingEncoding:NSUTF8StringEncoding]];
		}
		
		if ([[windowOptions objectForKey:@"modal"] boolValue])
			[nibController runModal];
	}
	else if([command isEqualToString:@"wait"])
	{
		NSString* token = [args lastObject];
		TMDNibController* nibController = [Nibs objectForKey:token];
		[nibController notifyFileHandle:[options objectForKey:@"stdout"]];
	}
	else if([command isEqualToString:@"update"])
	{
		NSString* token = [args lastObject];
		TMDNibController* nibController = [Nibs objectForKey:token];
		id newParameters = [TMDCommand readPropertyList:[options objectForKey:@"stdin"]];
		[nibController updateParametersWith:newParameters];
	}
	else if([command isEqualToString:@"list"])
	{
		NSFileHandle* fh = [options objectForKey:@"stdout"];
		enumerate([Nibs allKeys], NSString* token)
		{
			TMDNibController* nibController = [Nibs objectForKey:token];
			[fh writeData:[[NSString stringWithFormat:@"%@ (%@)\n", token, [[nibController window] title]] dataUsingEncoding:NSUTF8StringEncoding]];
		}
	}
	else if([command isEqualToString:@"close"])
	{
		NSString* token = [args lastObject];
		[[Nibs objectForKey:token] tearDown];
	}
}
@end
