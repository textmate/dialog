
#import "TextMate.h"


static CGFloat insertionDelayForNewDoc = 0.1f;

// Declarations to avoid compiler warnings
@interface NSObject (OakTextViewPrivate)
- (id)insertSnippetWithOptions:(NSDictionary*)options;
- (void)makeTextViewFirstResponder:(id)sender;
- (void)newDocumentAndActivate:(id)sender;
@end

/**
 Returns the front most text view and by reference:
 - “isNew” – “YES” if no text view was found it was created a new document
 - “winForTextView” – the NSWindow which contains the the front most text view
 It returns “nil” if no text view could be found or created.
*/
id frontMostTextViewForSelector(SEL selector, BOOL *isNew, NSWindow* *winForTextView)
{

	// Return value if a new doc was created
	if(isNew) *isNew = false;

	// unique method for identifying a OakTextView
	SEL checkSelector = @selector(scopeContext);

	// Find the front most OakTextView
	for(NSWindow* win in [NSApp orderedWindows])
	{

		// Check the firstResponder to speed up the search
		if([[win firstResponder] respondsToSelector:checkSelector] 
				&& [[win firstResponder] respondsToSelector:selector])
		{
			if(winForTextView) *winForTextView = win;
			return [win firstResponder];
		}

		// Look for it in first level subViews
		NSMutableArray* allViews = [[[[win contentView] subviews] mutableCopy] autorelease];
		for(NSView* view in allViews)
		{
			if([view respondsToSelector:checkSelector] && [view respondsToSelector:selector])
			{
				if(winForTextView) *winForTextView = win;
				return view;
			}
		}

		// Look deeper for it in the second level subViews
		NSMutableArray* allSubViews = [NSMutableArray array];
		for(NSUInteger i = 0; i < [allViews count]; ++i)
			[allSubViews addObjectsFromArray:[(id)CFArrayGetValueAtIndex((CFArrayRef)allViews, i) subviews]];
		for(NSView* view in allSubViews)
		{
			if([view respondsToSelector:checkSelector] && [view respondsToSelector:selector])
			{
				if(winForTextView) *winForTextView = win;
				return view;
			}
		}

	}

	// If no textView was found create a new document
	if(id tmApp = [NSApp targetForAction:@selector(newDocument:)])
	{

		[tmApp newDocumentAndActivate:nil];

		if([[NSApp orderedWindows] count]
			&& [[[[NSApp orderedWindows] objectAtIndex:0] windowController] tryToPerform:
															@selector(makeTextViewFirstResponder:) with:nil])
		{
			id textView = [NSApp targetForAction:checkSelector];
			if(textView && [textView respondsToSelector:selector]) {
				if(isNew) *isNew = true;
				if(winForTextView) *winForTextView = [[NSApp orderedWindows] objectAtIndex:0];
				return textView;
			}
		}
	}

	return nil;

}

/**
 Tries to insert “someText” as text into the front most text view.
*/
void insert_text (NSString* someText)
{
	BOOL isNewDocument = false;
	if(id textView = frontMostTextViewForSelector(@selector(insertText:), &isNewDocument, NULL))
	{
		if(isNewDocument) // delay the insertion to let TM finish the initialization of the new doc
			[textView performSelector:@selector(insertText:) withObject:someText afterDelay:insertionDelayForNewDoc];
		else
			[textView insertText:someText];
	}
}

/**
 Tries to insert “aSnippet” as snippet into the front most text view
 and set the key focus to the current document.
*/
void insert_snippet (NSString* aSnippet)
{
	BOOL isNewDocument = false;
	NSWindow *win = nil;
	if(id textView = frontMostTextViewForSelector(@selector(insertSnippetWithOptions:), &isNewDocument, &win))
	{
		if(isNewDocument) // delay the insertion to let TM finish the initialization of the new doc
			[textView performSelector:@selector(insertSnippetWithOptions:)
				withObject:[NSDictionary dictionaryWithObject:aSnippet forKey:@"content"] afterDelay:insertionDelayForNewDoc];
		else
			[textView insertSnippetWithOptions:
				[NSDictionary dictionaryWithObject:aSnippet forKey:@"content"]];
		
		// Since after inserting a snippet the user should interact with the snippet
		// set key focus to current textView
		[win makeKeyWindow];
	}
}
