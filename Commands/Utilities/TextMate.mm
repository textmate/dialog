#import "TextMate.h"

@interface NSObject (OakTextViewPrivate)
- (id)insertSnippetWithOptions:(NSDictionary*)options;
@end

#if 0
@interface NSWorkspace (ProcessSerialNumberFinder)
- (ProcessSerialNumber)processSerialNumberForApplicationWithIdentifier:(NSString *)identifier;
@end

@implementation NSWorkspace (ProcessSerialNumberFinder)
- (ProcessSerialNumber)processSerialNumberForApplicationWithIdentifier:(NSString *)identifier
{
	ProcessSerialNumber psn = {0, 0};

	for(NSEnumerator *enumerator = [[self launchedApplications] objectEnumerator]; NSDictionary *dict = [enumerator nextObject]; )
	{
		if([[dict objectForKey:@"NSApplicationBundleIdentifier"] isEqualToString:identifier])
		{
			psn.highLongOfPSN = [[dict objectForKey:@"NSApplicationProcessSerialNumberHigh"] longValue];
			psn.lowLongOfPSN  = [[dict objectForKey:@"NSApplicationProcessSerialNumberLow"] longValue];
			break;
		}
	}
	
	return psn;
}
@end
#endif

@implementation TextMate
+ (void)insertText:(NSString*)text asSnippet:(BOOL)asSnippet
{
	id textView = nil;
	if(asSnippet && (textView = [NSApp targetForAction:@selector(insertSnippetWithOptions:)]))
		[textView insertSnippetWithOptions:[NSDictionary dictionaryWithObject:text forKey:@"content"]];
	else if(textView = [NSApp targetForAction:@selector(insertText:)])
		[textView insertText:text];

	// // ProcessSerialNumber psn = [[NSWorkspace sharedWorkspace] processSerialNumberForApplicationWithIdentifier:@"com.macromates.textmate"];
	// ProcessSerialNumber psn = { 0, kCurrentProcess }; // Could use this once inside TM?
	// 
	// NSAppleEventDescriptor *targetDesc = [NSAppleEventDescriptor descriptorWithDescriptorType:'psn ' bytes:&psn length:sizeof(psn)];
	// NSAppleEventDescriptor *descriptor = [NSAppleEventDescriptor appleEventWithEventClass:'ISTR'
	//                                                                                  eventID:'ISTR'
	//                                                                         targetDescriptor:targetDesc
	//                                                                                 returnID:kAutoGenerateReturnID
	//                                                                            transactionID:kAnyTransactionID];
	// 
	// [descriptor setDescriptor:[NSAppleEventDescriptor descriptorWithString:text] forKeyword:'----'];
	// [descriptor setDescriptor:[NSAppleEventDescriptor descriptorWithEnumCode:asSnippet ? 'yes ' : 'no  '] forKeyword:'SNIP'];
	// 
	// AESendMessage([descriptor aeDesc], NULL, kAENoReply, kAEDefaultTimeout);
}
@end
