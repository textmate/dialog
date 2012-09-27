#import <Carbon/Carbon.h>
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

@interface DialogPopupMenuTarget : NSObject
{
	NSInteger selectedIndex;
}
@property NSInteger selectedIndex;
@end

@implementation DialogPopupMenuTarget
@synthesize selectedIndex;
- (id)init
{
	if((self = [super init]))
		self.selectedIndex = NSNotFound;
	return self;
}

- (BOOL)validateMenuItem:(NSMenuItem*)menuItem
{
	return [menuItem action] == @selector(takeSelectedItemIndexFrom:);
}

- (void)takeSelectedItemIndexFrom:(id)sender
{
	NSAssert([sender isKindOfClass:[NSMenuItem class]], @"Unexpected sender for menu target");
	self.selectedIndex = [(NSMenuItem*)sender tag];
}
@end

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
	return @"Presents a menu using the given structure and returns the option chosen by the user.";
}

- (NSString *)usageForInvocation:(NSString *)invocation;
{
	return [NSString stringWithFormat:@"\t%1$@ --items '({title = foo;}, {separator = 1;}, {header=1; title = bar;}, {title = baz;})'\n", invocation];
}

- (void)handleCommand:(CLIProxy*)proxy
{
	NSDictionary* args = [proxy parameters];
	NSArray* menuItems = [args objectForKey:@"items"];

	// FIXME this is needed only because we presently can’t express argument constraints (CLIProxy would otherwise correctly validate/convert CLI arguments)
	if([menuItems isKindOfClass:[NSString class]])
		menuItems = [NSPropertyListSerialization propertyListFromData:[(NSString*)menuItems dataUsingEncoding:NSUTF8StringEncoding] mutabilityOption:NSPropertyListImmutable format:nil errorDescription:NULL];

	NSMenu* menu = [[[NSMenu alloc] init] autorelease];
	[menu setFont:[NSFont menuFontOfSize:([[NSUserDefaults standardUserDefaults] integerForKey:@"OakBundleManagerDisambiguateMenuFontSize"] ?: [NSFont smallSystemFontSize])]];
	DialogPopupMenuTarget* menuTarget = [[[DialogPopupMenuTarget alloc] init] autorelease];

	int item_id = 0;
	bool in_section = false;
	enumerate(menuItems, NSDictionary* menuItem)
	{
		if([[menuItem objectForKey:@"separator"] intValue])
		{
			[menu addItem:[NSMenuItem separatorItem]];
		}
		else if([[menuItem objectForKey:@"header"] intValue])
		{
			[menu addItemWithTitle:[menuItem objectForKey:@"title"] action:NULL keyEquivalent:@""];
			in_section = true;
		}
		else
		{
			NSMenuItem* theItem = [menu addItemWithTitle:[menuItem objectForKey:@"title"] action:@selector(takeSelectedItemIndexFrom:) keyEquivalent:@""];
			[theItem setTarget:menuTarget];
			[theItem setTag:item_id];
			if(++item_id <= 10)
			{
				[theItem setKeyEquivalent:[NSString stringWithFormat:@"%d", item_id % 10]];
				[theItem setKeyEquivalentModifierMask:0];
			}
			if (in_section)
				[theItem setIndentationLevel:1];
		}
	}

	NSPoint pos = [NSEvent mouseLocation];
	if(id textView = [NSApp targetForAction:@selector(positionForWindowUnderCaret)])
		pos = [textView positionForWindowUnderCaret];
	

	if([menu popUpMenuPositioningItem:nil atLocation:pos inView:nil] && menuTarget.selectedIndex != NSNotFound)
		[TMDCommand writePropertyList:[menuItems objectAtIndex:menuTarget.selectedIndex] toFileHandle:[proxy outputHandle]];
}
@end
