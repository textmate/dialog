#import <Cocoa/Cocoa.h>
#import <Foundation/Foundation.h>
#import "../../TMDCommand.h"
#import "../../Dialog2.h"
#import "TMDHTMLTips.h"

@interface NSObject (OakTextView)
- (NSPoint)positionForWindowUnderCaret;
@end

@interface NSData (UTF8String)
- (NSString *)UTF8String;
@end

@implementation NSData (UTF8String)
- (NSString *)UTF8String
{
	char *string = new char[[self length] + 1];
	strcpy(string, (const char*)[self bytes]);
	string[[self length]] = '\0';
	NSString *result = [NSString stringWithUTF8String:string];
	return result;
}
@end

@interface TMDHTMLTipsCommand : TMDCommand
@end

@implementation TMDHTMLTipsCommand
+ (void)load
{
	[TMDCommand registerObject:[self new] forCommand:@"html-tip"];
}

- (void)handleCommand:(NSDictionary *)options
{
	NSFileHandle *stdinFP = (NSFileHandle *)[options objectForKey:@"stdin"];
	NSData *data = [stdinFP readDataToEndOfFile];
	
	if ([data length] == 0)
		return;
	
	NSString *content = [data UTF8String];
	
	NSPoint pos = NSZeroPoint;

	if(id textView = [NSApp targetForAction:@selector(positionForWindowUnderCaret)])
		pos = [textView positionForWindowUnderCaret];

	TMDHTMLTips* tooltip = [[TMDHTMLTips alloc] init];
	[tooltip setHTML:content];
	NSLog(@"%s point: %@", __PRETTY_FUNCTION__, NSStringFromPoint(pos));
	// pos.y = 900;
	// pos.x = 0;
	[[tooltip window] setFrameTopLeftPoint:pos];
	NSLog(@"%s point: %@", __PRETTY_FUNCTION__, NSStringFromPoint([[tooltip window] frame].origin));

	[self performSelector: @selector(eventHandlingForHTMLTip:)
				withObject: tooltip
				afterDelay: 0.1];
}

-(void) eventHandlingForHTMLTip:(TMDHTMLTips *)tooltip
{	
	NSDate *distantFuture = [NSDate distantFuture];
	NSEvent *event;

	do {
		event = [NSApp nextEventMatchingMask: NSAnyEventMask
								   untilDate: distantFuture
									  inMode: NSDefaultRunLoopMode
									 dequeue: YES];
		
		if (event != nil)
		{
			NSEventType t = [event type];
			[NSApp sendEvent:event];
			if (t == NSKeyDown || t == NSMouseMoved || t == NSScrollWheel) {
				break;
			}
		}
	}
	while(1);

	[tooltip fade];
}
@end
