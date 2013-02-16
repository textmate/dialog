#import "../Dialog2.h"
#import "../TMDCommand.h"
#import "Utilities/TextMate.h" // -positionForWindowUnderCaret

// ========
// = Menu =
// ========

/*
echo '{ items = ({title = "foo"; header = 1;},{title = "bar";}); }' | "$DIALOG" menu
"$DIALOG" menu --items '({title = "foo"; header = 1;},{title = "bar";})'
*/

#define kMenuTitleKey     @"title"
#define kMenuItemsKey     @"items"
#define kMenuSeparatorKey @"separator"
#define kMenuHeaderKey    @"header"
#define kMenuMenuKey      @"menu"

@interface DialogPopupMenuTarget : NSObject
{
	NSDictionary *selectedObject;
}
@property (nonatomic, retain) NSDictionary *selectedObject;
@end

@implementation DialogPopupMenuTarget
@synthesize selectedObject;
- (id)init
{
	if((self = [super init]))
		self.selectedObject = nil;
	return self;
}

- (BOOL)validateMenuItem:(NSMenuItem*)menuItem
{
	return [menuItem action] == @selector(takeSelectedItemFrom:);
}

- (void)takeSelectedItemFrom:(id)sender
{
	NSAssert([sender isKindOfClass:[NSMenuItem class]], @"Unexpected sender for menu target");
	self.selectedObject = [(NSMenuItem*)sender representedObject];
}

- (void)dealloc
{
	if(selectedObject) [selectedObject release];
	[super dealloc];
}
@end

@interface TMDMenuCommand : TMDCommand
{
}
@end

@implementation TMDMenuCommand
+ (void)load
{
	[TMDCommand registerObject:[self new] forCommand:kMenuMenuKey];
}

- (NSString *)commandDescription
{
	return @"Presents a menu using the given structure and returns the underlying object chosen by the user.";
}

- (NSString *)usageForInvocation:(NSString *)invocation;
{
	return [NSString stringWithFormat:@"\
	%1$@ --items '({title = foo;}, {separator = 1;}, {header=1; title = bar;}, {title = baz;})'\n\
	%1$@ --items '({title = foo;}, {separator = 1;}, {header=1; title = bar1;}, {title = baz; ofHeader = bar1;}, {header=1; title = bar2;}, {title = baz; ofHeader = bar2;}, {menu = { title = aSubmenu; items = ( {title = baz; ofSubmenu = aSubmenu;}, {separator = 1;}, {header=1; title = bar2;}, {title = subbaz;} ); };})'\n",
			 invocation];
}

- (void)handleCommand:(CLIProxy*)proxy
{
	NSDictionary* args = [proxy parameters];
	NSArray* menuItems = [args objectForKey:kMenuItemsKey];

	// FIXME this is needed only because we presently can’t express argument constraints (CLIProxy would otherwise correctly validate/convert CLI arguments)
	if([menuItems isKindOfClass:[NSString class]])
		menuItems = [NSPropertyListSerialization propertyListFromData:[(NSString*)menuItems dataUsingEncoding:NSUTF8StringEncoding] mutabilityOption:NSPropertyListImmutable format:nil errorDescription:NULL];

	NSMenu* menu = [[[NSMenu alloc] init] autorelease];
	[menu setFont:[NSFont menuFontOfSize:([[NSUserDefaults standardUserDefaults] integerForKey:@"OakBundleManagerDisambiguateMenuFontSize"] ?: [NSFont smallSystemFontSize])]];
	DialogPopupMenuTarget* menuTarget = [[[DialogPopupMenuTarget alloc] init] autorelease];

	NSInteger item_id_key = 0;
	BOOL in_section = false;

	enumerate(menuItems, NSDictionary* menuItem)
	{
		// check for separator
		if([[menuItem objectForKey:kMenuSeparatorKey] intValue])
		{
			[menu addItem:[NSMenuItem separatorItem]];
		}
		// check for header and indent following items
		else if([[menuItem objectForKey:kMenuHeaderKey] intValue])
		{
			if(NSString *item = [menuItem objectForKey:kMenuTitleKey])
			{
				[menu addItemWithTitle:item action:NULL keyEquivalent:@""];
				in_section = true;
			}
		}
		// check for a submenu
		else if(NSDictionary *aSubMenu = [menuItem objectForKey:kMenuMenuKey])
		{ 
			if([aSubMenu objectForKey:kMenuTitleKey] &&
				[aSubMenu objectForKey:kMenuItemsKey] &&
				[[aSubMenu objectForKey:kMenuItemsKey] isKindOfClass:[NSArray class]])
			{
				NSArray *subMenuItems = (NSArray*)[aSubMenu objectForKey:kMenuItemsKey];
				NSMenu* submenu = [[[NSMenu alloc] init] autorelease];
				[submenu setFont:[NSFont menuFontOfSize:([[NSUserDefaults standardUserDefaults] integerForKey:@"OakBundleManagerDisambiguateMenuFontSize"] ?: [NSFont smallSystemFontSize])]];

				NSString *submenuTitle = [aSubMenu objectForKey:kMenuTitleKey];
				BOOL subin_section = false;

				enumerate(subMenuItems, NSDictionary* menuItem)
				{
					if([[menuItem objectForKey:kMenuSeparatorKey] intValue])
					{
						[submenu addItem:[NSMenuItem separatorItem]];
					}
					else if([[menuItem objectForKey:kMenuHeaderKey] intValue])
					{
						if(NSString *item = [menuItem objectForKey:kMenuTitleKey])
						{
							[submenu addItemWithTitle:item action:NULL keyEquivalent:@""];
							subin_section = true;
						}
					}
					else if(NSString *item = [menuItem objectForKey:kMenuTitleKey])
					{
						NSMenuItem* theItem = [submenu addItemWithTitle:item action:@selector(takeSelectedItemFrom:) keyEquivalent:@""];
						[theItem setTarget:menuTarget];
						[theItem setRepresentedObject:menuItem];
						if(subin_section)
							[theItem setIndentationLevel:1];
					}
				}
				NSMenuItem* subMenuItem = [[NSMenuItem alloc] initWithTitle:submenuTitle action:NULL keyEquivalent:@""];
				[subMenuItem setSubmenu:submenu];
				[menu addItem:subMenuItem];
				[subMenuItem release];
			}
		}
		// check for items specified by the key 'title'
		else
		{
			if(NSString *item = [menuItem objectForKey:kMenuTitleKey])
			{
				NSMenuItem* theItem = [menu addItemWithTitle:item action:@selector(takeSelectedItemFrom:) keyEquivalent:@""];
				[theItem setTarget:menuTarget];
				[theItem setRepresentedObject:menuItem];
				if(++item_id_key <= 10)
				{
					[theItem setKeyEquivalent:[NSString stringWithFormat:@"%ld", item_id_key % 10]];
					[theItem setKeyEquivalentModifierMask:0];
				}
				if(in_section)
					[theItem setIndentationLevel:1];
			}
		}
	}

	NSPoint pos = [NSEvent mouseLocation];
	if(id textView = [NSApp targetForAction:@selector(positionForWindowUnderCaret)])
		pos = [textView positionForWindowUnderCaret];
	

	if([menu popUpMenuPositioningItem:nil atLocation:pos inView:nil] && menuTarget.selectedObject)
		[TMDCommand writePropertyList:menuTarget.selectedObject toFileHandle:[proxy outputHandle] withProxy:proxy];

}
@end
