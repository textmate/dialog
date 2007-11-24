//
//  TMDNibController.mm
//  Dialog2
//
//  Created by Ciaran Walsh on 23/11/2007.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <string>
#import "../../Dialog2.h"
#import "../../TMDCommand.h"
#import "TMDNibController.h"

static unsigned int NibTokenCount = 0;

@implementation TMDNibController
- (NSWindow*)window					{ return window; }
- (id)parameters						{ return parameters; }
- (NSString*)token					{ return [NSString stringWithFormat:@"%u", token]; }
- (BOOL)autoCloses					{ return autoCloses; }

- (void)setAutoCloses:(BOOL)flag	{ autoCloses = flag; }

- (void)setWindow:(NSWindow*)aWindow
{
	if(window != aWindow)
	{
		[window setDelegate:nil];
		[window release];
		window = [aWindow retain];
		[window setDelegate:self];
		[window setReleasedWhenClosed:NO]; // incase this was set wrong in IB
	}
}

- (void)setParameters:(id)someParameters
{
	if(parameters != someParameters)
	{
		[parameters release];
		parameters = [someParameters retain];
	}
}

- (void)updateParametersWith:(id)plist
{
	enumerate([plist allKeys], id key)
		[parameters setValue:[plist valueForKey:key] forKey:key];
}

- (void)instantiateNib:(NSNib*)aNib
{
	BOOL didInstantiate = NO;
	isRunningModal      = NO;
	@try {
	 	didInstantiate = [aNib instantiateNibWithOwner:self topLevelObjects:&topLevelObjects];
	}
	@catch(NSException* e) {
		// our retain count is too high if we reach this branch (<rdar://4803521>) so no RAII idioms for Cocoa, which is why we have the didLock variable, etc.
		NSLog(@"%s failed to instantiate nib (%@)", _cmd, [e reason]);
		return;
	}

	[topLevelObjects retain];
	enumerate(topLevelObjects, id object)
	{
		if([object isKindOfClass:[NSWindow class]])
			[self setWindow:object];
	}
	
	if(!window)
	{
		NSLog(@"%s didn't find a window in nib", _cmd);
		return;
	}
}

- (void)showWindowAndCenter:(BOOL)shouldCenter
{
	if (shouldCenter)
	{
		if(NSWindow* keyWindow = [NSApp keyWindow])
		{
			NSRect frame = [window frame], parentFrame = [keyWindow frame];
			[window setFrame:NSMakeRect(NSMidX(parentFrame) - 0.5 * NSWidth(frame), NSMidY(parentFrame) - 0.5 * NSHeight(frame), NSWidth(frame), NSHeight(frame)) display:NO];
		}
		else
		{
			[window center];
		}
	}

	[window makeKeyAndOrderFront:self];
}

- (void)runModal
{
	// TODO: When TextMate is capable of running script I/O in it's own thread(s), modal blocking
	// can go away altogether.
	isRunningModal = YES;
	[NSApp runModalForWindow:window];
}

- (id)initWithNibName:(NSString*)aName
{
	if(self = [super init])
	{
		if(![[NSFileManager defaultManager] fileExistsAtPath:aName])
		{
			NSLog(@"%s nib file not found: %@", _cmd, aName);
			[self release];
			return nil;
		}

		parameters = [[NSMutableDictionary dictionaryWithObjectsAndKeys:
			self, @"controller",
			nil] retain];

		NSNib* nib = [[[NSNib alloc] initWithContentsOfURL:[NSURL fileURLWithPath:aName]] autorelease];
		if(!nib)
		{
			NSLog(@"%s failed loading nib: %@", _cmd, aName);
			[self release];
			return nil;
		}

		token = ++NibTokenCount;
		[self instantiateNib:nib];
	}
	return self;
}

- (void)makeControllersCommitEditing
{
	enumerate(topLevelObjects, id object)
	{
		if([object respondsToSelector:@selector(commitEditing)])
			[object commitEditing];
	}

	[[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)tearDown
{
	NSLog(@"%s isRunningModal: %d", _cmd, isRunningModal);
	if (isRunningModal)
		[NSApp stopModal];

	[[self retain] autorelease];

	[parameters removeObjectForKey:@"controller"];
	// [self return:parameters]; // only if the non-async version is used

	// if we do not manually unbind, the object in the nib will keep us retained, and thus we will never reach dealloc
	enumerate(topLevelObjects, id object)
	{
		if([object isKindOfClass:[NSObjectController class]])
			[object unbind:@"contentObject"];
	}

	[Nibs removeObjectForKey:[self token]];
}

- (void)dealloc
{
	[self setWindow:nil];
	[self setParameters:nil];

	enumerate(topLevelObjects, id object)
		[object release];
	[topLevelObjects release];

	[fileHandles release];
	[super dealloc];
}

- (void)windowWillClose:(NSNotification*)aNotification
{
	NSLog(@"[%@ windowWillClose:%@]", [self class], aNotification);
	[self tearDown];
}

// ==================================
// = Getting stuff from this window =
// ==================================
- (void)notifyFileHandle:(NSFileHandle*)aFileHandle
{
	if(!fileHandles)
		fileHandles = [NSMutableArray new];
	[fileHandles addObject:aFileHandle];
}

- (void)return:(id)res
{
	[self makeControllersCommitEditing];

	enumerate(fileHandles, NSFileHandle* fileHandle)
		[TMDCommand writePropertyList:res toFileHandle:fileHandle];

	[fileHandles release];
	fileHandles = nil;

	if([self autoCloses])
		[self tearDown];
}

// ================================================
// = Faking a returnArgument:[…:]* implementation =
// ================================================
// returnArgument: implementation. See <http://lists.macromates.com/pipermail/textmate/2006-November/015321.html>
- (NSMethodSignature*)methodSignatureForSelector:(SEL)aSelector
{
	NSLog(@"[%@ methodSignatureForSelector:%@]", [self class], NSStringFromSelector(aSelector));
	NSString* str = NSStringFromSelector(aSelector);
	if([str hasPrefix:@"returnArgument:"])
	{
		std::string types;
		types += @encode(void);
		types += @encode(id);
		types += @encode(SEL);
	
		unsigned numberOfArgs = [[str componentsSeparatedByString:@":"] count];
		while(numberOfArgs-- > 1)
			types += @encode(id);
	
		return [NSMethodSignature signatureWithObjCTypes:types.c_str()];
	}
	return [super methodSignatureForSelector:aSelector];
}

- (void)forwardInvocation:(NSInvocation*)invocation
{
	NSLog(@"[%@ forwardInvocation:%@]", [self class], invocation);
	NSString* str = NSStringFromSelector([invocation selector]);
	if([str hasPrefix:@"returnArgument:"])
	{
		NSArray* argNames = [str componentsSeparatedByString:@":"];

		NSMutableDictionary* res = [NSMutableDictionary dictionary];
		for(size_t i = 2; i < [[invocation methodSignature] numberOfArguments]; ++i)
		{
			id arg = nil;
			if([invocation getArgument:&arg atIndex:i], arg)
				[res setObject:arg forKey:[argNames objectAtIndex:i - 2]];
		}

		[self return:res];
	}
	else
	{
		[super forwardInvocation:invocation];
	}
}

// ===============================
// = The old performButtonClicl: =
// ===============================
- (IBAction)performButtonClick:(id)sender
{
	NSMutableDictionary* res = [[parameters mutableCopy] autorelease];
	[res removeObjectForKey:@"controller"];

	if([sender respondsToSelector:@selector(title)])
		[res setObject:[sender title] forKey:@"returnButton"];
	if([sender respondsToSelector:@selector(tag)])
		[res setObject:[NSNumber numberWithInt:[sender tag]] forKey:@"returnCode"];

	[self return:res];
}
@end
