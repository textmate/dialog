#import <Carbon/Carbon.h>
#import "../Dialog2.h"
#import "../TMDCommand.h"
#import "Utilities/TextMate.h" // -positionForWindowUnderCaret

// ========
// = Menu =
// ========

/*
echo '{ menuItems = ({title = "foo"; header = 1;},{title = "bar";}); }' | "$DIALOG" menu
*/

@interface TMDMenuCommand : TMDCommand
{
}
@end

@implementation TMDMenuCommand
+ (void)load
{
	[TMDCommand registerObject:[self new] forCommand:@"menu"];
}

- (NSString *)commandDescription
{
	return @"Presents a menu using the given structure and returns the option chosen by the user";
}

- (NSString *)usageForInvocation:(NSString *)invocation;
{
	return [NSString stringWithFormat:@"The menu structure should be given as a property list on STDIN, e.g.\n"
	       @"echo '{ menuItems = ({title = \"foo\";}, {separator = 1;}, {header=1; title=\"bar\";}, {title = \"baz\";}); }' | %@",invocation];
}

- (void)handleCommand:(CLIProxy*)interface
{
	MenuRef menu_ref;
	CreateNewMenu(0 /* menu id */, kMenuAttrDoNotCacheImage, &menu_ref);
	SetMenuFont(menu_ref, 0, [[NSUserDefaults standardUserDefaults] integerForKey:@"OakBundleManagerDisambiguateMenuFontSize"] ?: 12);

	int item_id = 0, item_index = 0;
	bool in_section = false;
	NSArray* menuItems = [[interface readPropertyListFromInput] objectForKey:@"menuItems"];
	enumerate(menuItems, NSDictionary* menuItem)
	{
		if([[menuItem objectForKey:@"separator"] intValue])
		{
			AppendMenuItemTextWithCFString(menu_ref, CFSTR(""), kMenuItemAttrSeparator, item_index++, NULL);
		}
		else if([[menuItem objectForKey:@"header"] intValue])
		{
			AppendMenuItemTextWithCFString(menu_ref, (CFStringRef)[menuItem objectForKey:@"title"], kMenuItemAttrSectionHeader, item_index++, NULL);
			in_section = true;
		}
		else
		{
			MenuItemIndex index;
			AppendMenuItemTextWithCFString(menu_ref, (CFStringRef)[menuItem objectForKey:@"title"], 0, item_index++, &index);
			if(++item_id <= 10)
			{
				SetMenuItemCommandKey(menu_ref, index, NO, item_id == 10 ? '0' : '1' + (item_id-1));
				SetMenuItemModifiers(menu_ref, index, kMenuNoCommandModifier);
			}
			if (in_section)
				SetMenuItemIndent(menu_ref, index, 1);
		}
		// AppendMenuItemTextWithCFString(menu_ref, NULL, kMenuItemAttrSectionHeader, 0, NULL);
	}

	NSPoint pos = NSZeroPoint;
	if(id textView = [NSApp targetForAction:@selector(positionForWindowUnderCaret)])
		pos = [textView positionForWindowUnderCaret];

	NSRect mainScreen = [[NSScreen mainScreen] frame];
	enumerate([NSScreen screens], NSScreen* candidate)
	{
		if(NSMinX([candidate frame]) == 0.0f && NSMinY([candidate frame]) == 0.0f)
			mainScreen = [candidate frame];
	}

	short top = lroundf(NSMaxY(mainScreen) - pos.y);
	short left = lroundf(pos.x - NSMinX(mainScreen));
	long res = PopUpMenuSelect(menu_ref, top, left, 0 /* pop-up item */);

	NSMutableDictionary* selectedItem = [NSMutableDictionary dictionary];
	if(res != 0)
	{
		MenuCommand cmd = 0;
		GetMenuItemCommandID(menu_ref, res, &cmd);
		[selectedItem setObject:[NSNumber numberWithUnsignedInt:(unsigned)cmd] forKey:@"selectedIndex"];
		[selectedItem setObject:[menuItems objectAtIndex:(unsigned)cmd] forKey:@"selectedMenuItem"];
	}

	[TMDCommand writePropertyList:selectedItem toFileHandle:[interface outputHandle]];

	DisposeMenu(menu_ref);
}
@end
