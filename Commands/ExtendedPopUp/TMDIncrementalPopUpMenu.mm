//
//  TMDIncrementalPopUpMenu.mm
//
//  Created by Joachim Mårtensson on 2007-08-10.
//

#import "TMDIncrementalPopUpMenu.h"
#import "../Utilities/TextMate.h" // -insertSnippetWithOptions
#import "../../TMDCommand.h" // -writeString:
#import "../../Dialog2.h"

@interface NSEvent (DeviceDelta)
- (float)deviceDeltaX;
- (float)deviceDeltaY;
@end

@interface TMDIncrementalPopUpMenu (Private)
- (NSFont*)font;
- (NSRect)rectOfMainScreen;
@end

@implementation TMDIncrementalPopUpMenu
- (id)initWithProxy:(CLIProxy*)proxy;
{
	if(self = [self initWithContentRect:NSZeroRect styleMask:NSBorderlessWindowMask backing:NSBackingStoreBuffered defer:NO])
	{
		NSString* currentWord = [proxy valueForOption:@"current-word"];
		if(!currentWord)
			currentWord = @"";
		mutablePrefix = [currentWord mutableCopy];

		stringWidth   = [mutablePrefix sizeWithAttributes:[NSDictionary dictionaryWithObject:[self font] forKey:NSFontAttributeName]].width;

		extraChars = [[proxy valueForOption:@"extra-chars"] retain];

		NSDictionary* initialValues = [proxy readPropertyListFromInput];

		suggestions = [[initialValues objectForKey:@"suggestions"] retain];

		// Convert image paths to NSImages
		NSDictionary* imagePaths    = [[[initialValues objectForKey:@"images"] retain] autorelease];
		images = [[NSMutableDictionary alloc] initWithCapacity:[imagePaths count]];

		NSEnumerator *imageEnum = [imagePaths keyEnumerator];
		while (NSString* imageName = [imageEnum nextObject]) {
			NSString* imagePath = [imagePaths objectForKey:imageName];
			NSImage* image      = [[NSImage alloc] initByReferencingFile:imagePath];
			if(image && [image isValid])
				[images setObject:image forKey:imageName];
			[image release];
		}

		env          = [[proxy environment] retain];
		extraOptions = [[initialValues objectForKey:@"extraOptions"] retain];
        
		if([proxy valueForOption:@"static-prefix"])
			staticPrefix = [[proxy valueForOption:@"static-prefix"] retain];
		else
			staticPrefix = @"";

		shell = [[proxy valueForOption:@"shell-cmd"] retain];


		// Window setup
		[self setReleasedWhenClosed:YES];
		[self setLevel:NSStatusWindowLevel];
		[self setHidesOnDeactivate:YES];
		[self setHasShadow:YES];

		NSScrollView* scrollView = [[NSScrollView alloc] initWithFrame:NSZeroRect];
		{
			[scrollView setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
			[scrollView setAutohidesScrollers:YES];
			[scrollView setHasVerticalScroller:YES];
			[[scrollView verticalScroller] setControlSize:NSSmallControlSize];

			theTableView = [[NSTableView alloc] initWithFrame:NSZeroRect];
			{
				[theTableView setFocusRingType:NSFocusRingTypeNone];
				[theTableView setAllowsEmptySelection:NO];
				[theTableView setHeaderView:nil];

				NSTableColumn *column = [[NSTableColumn alloc] initWithIdentifier:@"foo"];
				{
					[column setDataCell:[NSClassFromString(@"OakImageAndTextCell") new]];
					[column setEditable:NO];
					[theTableView addTableColumn:column];
					[column setWidth:[theTableView bounds].size.width];
				}
				[column release];

				[theTableView setDataSource:self];

				[scrollView setDocumentView:theTableView];
			}
			[theTableView release];

			[self setContentView:scrollView];


			[self filter];
			closeMe = NO;
		}
		[scrollView release];
	}

	return self;
}

- (void)orderFront:(id)sender
{
	[super orderFront:sender];
	[self performSelector:@selector(watchUserEvents) withObject:nil afterDelay:0.05];
}

- (void)watchUserEvents
{
	NSCharacterSet* whiteList = nil;
	if(extraChars)
		whiteList = [NSCharacterSet characterSetWithCharactersInString:extraChars];

	do
	{
		NSEvent* event = [NSApp nextEventMatchingMask:NSAnyEventMask
                                          untilDate:[NSDate distantFuture]
                                             inMode:NSDefaultRunLoopMode
                                            dequeue:YES];

		if(event != nil)
		{
			NSEventType t = [event type];
			if(t == NSKeyDown)
			{
				NSString* aString  = [event characters];
				unsigned int flags = [event modifierFlags];
				unichar key        = 0;
				if((flags & NSControlKeyMask) || (flags & NSAlternateKeyMask) || (flags & NSCommandKeyMask))
				{
					[NSApp sendEvent:event];
					break;
				}
				else if([aString length] == 1)
				{
					key = [aString characterAtIndex:0];
					if(key == NSCarriageReturnCharacter)
					{
						[self keyDown:event];
						break;
					}
					else if(key == NSBackspaceCharacter || key == NSDeleteCharacter)
					{
						[NSApp sendEvent:event];
						if([[self mutablePrefix] length] > 0)
						{
							[self keyDown:event];
						}
						else
						{
							break;
						}
					}
					else if ([event keyCode] == 53)
					{
						break;
					}
					else if(key == NSTabCharacter)
					{
						if([[self filtered] count] == 0)
						{
							[NSApp sendEvent:event];
							break;
						}
						if([[self filtered] count] == 1)
						{
							[self keyDown:event];
							break;
						}
						[self keyDown:event];
					}   
					else if(key == NSUpArrowFunctionKey || key == NSDownArrowFunctionKey)
					{ 
						[[self theTableView] keyDown:event];
					}
					else if(key == NSEndFunctionKey)
					{ 
						[self moveToEndOfDocument:self];
					}
					else if(key == NSHomeFunctionKey)
					{ 
						[self moveToBeginningOfDocument:self];
					}
					else if(key == NSPageDownFunctionKey)
					{ 
						[self pageDown:self];
					}
					else if(key == NSPageUpFunctionKey)
					{ 
						[self pageUp:self];
					}
					else if([[NSCharacterSet alphanumericCharacterSet] characterIsMember:key] || (whiteList && [whiteList characterIsMember:key]))
					{
						[NSApp sendEvent:event];
						[self keyDown:event];
					}
					else
					{
						[NSApp sendEvent:event];
						//[xPopUp keyDown:event];
						break;
					}
				}
				else
				{
						[NSApp sendEvent:event];
						//[xPopUp keyDown:event];
						break;
				}
			}
			else if(t == NSScrollWheel)
			{
 				if([event deviceDeltaY] >= 0.0)
 					[self scrollLineUp:self];
				else
					[self scrollLineDown:self];
			}
			else if(t == NSRightMouseDown || t == NSLeftMouseDown)
			{
				[NSApp sendEvent:event];
				if(! NSPointInRect([NSEvent mouseLocation], [self frame]))
					break;
			}
			else
			{ 
				[NSApp sendEvent:event];
			}
		}
	}
	while(!closeMe);
	[self close];
}

- (NSMutableString*)mutablePrefix;
{
	return mutablePrefix;
}
- (id)theTableView
{	
	return theTableView;
}
// osascript -e 'tell application "TextMate" to activate'$'\n''tell application "System Events" to keystroke (ASCII character 8)'
- (void)tab
{
	if([filtered count]>1)
	{
		NSEnumerator *enumerator = [filtered objectEnumerator];
		id firstObject = [enumerator nextObject];
		id eachString;
		id previousString = [firstObject objectForKey:@"filterOn"];
		if(!previousString)
			 previousString = [firstObject objectForKey:@"title"];
		id dict;
		while(dict = [enumerator nextObject])
		{
			eachString = [dict objectForKey:@"filterOn"];
			if(!eachString)
				 eachString = [dict objectForKey:@"title"];
			NSString *commonPrefix = [eachString commonPrefixWithString:previousString options:NSLiteralSearch];
			previousString = commonPrefix;
		}
		NSString* tStatic;// = [staticPrefix copy];
		NSString* temp = [staticPrefix stringByAppendingString:mutablePrefix];
		//[tStatic release];
		if([previousString length] > [temp length])
		{
			if(previousString)
			{
				tStatic = [previousString substringFromIndex:[temp length]];
				[mutablePrefix appendString:tStatic];
			}
			else
			{
				//NSLog(@"previousString was nil !!!: []", temp);
				//[temp release];
			}
			
			[self writeToTM:tStatic asSnippet:NO];
			[self filter];
		}

	}
	// [self close];
}

- (int)numberOfRowsInTableView:(NSTableView *)aTableView
{
	return [filtered count];
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
	NSImage* image = nil;
	
	NSString* imageName = [[filtered objectAtIndex:rowIndex] objectForKey:@"image"];
	if(imageName)
		image = [images objectForKey:imageName];
	
	[[aTableColumn dataCell] setImage:image];

	return [[filtered objectAtIndex:rowIndex] objectForKey:@"title"];
}

- (void)filter
{
	NSRect mainScreen = [self rectOfMainScreen];

	NSArray* myArray2;
	if([mutablePrefix length] > 0)
	{
		NSPredicate* predicate = [NSPredicate predicateWithFormat:@"filterOn BEGINSWITH %@ OR (filterOn == NULL AND title BEGINSWITH %@)", [staticPrefix stringByAppendingString:mutablePrefix], [staticPrefix stringByAppendingString:mutablePrefix]];
		myArray2 = [suggestions filteredArrayUsingPredicate:predicate];
		//[anArrayController rearrangeObjects];
	}
	else
	{
		myArray2 = suggestions;
	}
	NSPoint old = NSMakePoint([self frame].origin.x,[self frame].origin.y +[self frame].size.height);
	float newHeight = 0;
	if([myArray2 count]>MAX_ROWS)
	{
		newHeight = [theTableView rowHeight]*MAX_ROWS*1.15;
	}
	else if([myArray2 count]>1)
	{
		newHeight = [theTableView rowHeight]*[myArray2 count]*1.15;
	}
	else
	{
		newHeight = [theTableView rowHeight] * 1.2;
	}

	float maxLen = 1;
	NSString* item;
	int i;
	float maxWidth = [self frame].size.width;
	if([myArray2 count]>0)
	{
		for(i=0; i<[myArray2 count]; i++)
		{
			item = [[myArray2 objectAtIndex:i] objectForKey:@"title"];
			if([item length]>maxLen)
				maxLen = [item length];
		}
		maxWidth = maxLen*18;
		maxWidth = (maxWidth>340) ? 340 : maxWidth;
	}
	if(caretPos.y>=0 && (isAbove || caretPos.y<newHeight))
	{
		[self setAbove:YES];
		old.y = caretPos.y + (newHeight + [[NSUserDefaults standardUserDefaults] integerForKey:@"OakTextViewNormalFontSize"]*1.5);
	}
	if(caretPos.y<0 && (isAbove || (mainScreen.size.height-newHeight)<(caretPos.y*-1)))
	{
		old.y = caretPos.y + (newHeight + [[NSUserDefaults standardUserDefaults] integerForKey:@"OakTextViewNormalFontSize"]*1.5);
	}
	[self setFrame:NSMakeRect(old.x,old.y-newHeight,maxWidth,newHeight) display:YES];
	//NSLog(@"myArray2 retaincount %d",[myArray2 retainCount]);
	//NSLog(@"filtered retaincount in filter %d",[filtered retainCount]);
	//[self setValue:myArray2 forKey:@"filtered"];
	[self setFiltered:myArray2];
	//NSLog(@"filtered retaincount in filter after - %d",[filtered retainCount]);
	
}

- (NSFont*)font
{
	return [NSFont fontWithName:[[NSUserDefaults standardUserDefaults] stringForKey:@"OakTextViewNormalFontName"] ?:[[NSFont userFixedPitchFontOfSize:12.0] fontName]
                          size:[[NSUserDefaults standardUserDefaults] integerForKey:@"OakTextViewNormalFontSize"] ?: 12 ];
}

- (int) stringWidth;
{
	return stringWidth;
}

- (NSRect)rectOfMainScreen;
{
	NSRect mainScreen = [[NSScreen mainScreen] frame];
	enumerate([NSScreen screens], NSScreen* candidate)
	{
		if(NSMinX([candidate frame]) == 0.0f && NSMinY([candidate frame]) == 0.0f)
			mainScreen = [candidate frame];
	}
	return mainScreen;
}

- (void)setCaretPos:(NSPoint)aPos
{
	caretPos = aPos;

	[self setAbove:NO];

	NSRect mainScreen = [self rectOfMainScreen];

	int offx = (caretPos.x/mainScreen.size.width) + 1;
	if((caretPos.x + [self frame].size.width) > (mainScreen.size.width*offx))
		caretPos.x = caretPos.x - [self frame].size.width;
	caretPos.x = caretPos.x - [self stringWidth];

	if(caretPos.y>=0 && caretPos.y<[self frame].size.height)
	{
		caretPos.y = caretPos.y + ([self frame].size.height + [[NSUserDefaults standardUserDefaults] integerForKey:@"OakTextViewNormalFontSize"]*1.5);
		[self setAbove:YES];
	}
	if(caretPos.y<0 && (mainScreen.size.height-[self frame].size.height)<(caretPos.y*-1))
	{
		caretPos.y = caretPos.y + ([self frame].size.height + [[NSUserDefaults standardUserDefaults] integerForKey:@"OakTextViewNormalFontSize"]*1.5);
		[self setAbove:YES];
	}
	[self setFrameTopLeftPoint:caretPos];
}

- (void)setAbove:(BOOL)aBool
{
	isAbove = aBool;
}
- (BOOL)getCloseStatus
{
	return closeMe;
}
- (void)awakeFromNib
{
  //  [theTableView setNextResponder: self];
	[theTableView setTarget:self];
	[theTableView setDoubleAction:@selector(completeAndInsertSnippet:)];
}
- (void)completeAndInsertSnippet:(id)nothing
{
	if([theTableView selectedRow] != -1)
	{

		//id selection = [filtered objectAtIndex:[theTableView selectedRow]];
		NSMutableDictionary* selection = [NSMutableDictionary dictionary];
		[selection addEntriesFromDictionary:[filtered objectAtIndex:[theTableView selectedRow]]];
        [selection setObject:env forKey:@"environment"];
        [selection setValue:extraOptions forKey:@"extraOptions"];
		
		
		NSString* aString = [selection valueForKey:@"filterOn"];
		if(!aString)
			aString = [selection valueForKey:@"title"];
		NSString* temp = [staticPrefix stringByAppendingString:mutablePrefix];
		if([aString length] > [temp length])
		{
			NSString* temp2 = [aString substringFromIndex:[temp length]];
			[self writeToTM:temp2 asSnippet:NO];
		}
		if([selection valueForKey:@"snippet"])
		{
			//[self writeToTM:[[ob valueForKey:@"snippet"] copy] asSnippet:YES];
			[self writeToTM:[selection valueForKey:@"snippet"] asSnippet:YES];
		}
		else if(shell)
		{
			//NSLog(@"shell");
			NSString* fromShell =[[self executeShellCommand:shell WithDictionary:selection] retain];
			[self writeToTM:fromShell asSnippet:YES];
		}
		closeMe = YES;
	}
}


- (void)selectRow:(int)row
{
	[theTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
	[[self theTableView] scrollRowToVisible:row];
}

- (void)scrollLineUp:(id)sender
{
	int row = [theTableView selectedRow];
	if (--row >= 0) [self selectRow:row];
}
-(void)scrollLineDown:(id)sender
{
	int row = [theTableView selectedRow];
	if (++row < [filtered count]) [self selectRow:row];
}
- (void)moveToBeginningOfDocument:(id)sender 
{
	[self selectRow:0];
}
- (void)moveToEndOfDocument:(id)sender 
{
	[self selectRow:[filtered count]-1];
}
- (void)pageDown:(id)sender
{
	int oldIndex = [theTableView selectedRow];
	if([filtered count]<(MAX_ROWS+1))
		[self selectRow:[filtered count]-1];
	else
	{
		if(oldIndex+MAX_ROWS>=[filtered count])
			[self selectRow:[filtered count]-1];
		else 
			[self selectRow:oldIndex+MAX_ROWS-1];
		[[self theTableView] scrollRowToVisible:[theTableView selectedRow]];
	}

}
- (void)pageUp:(id)sender 
{
	int oldIndex = [theTableView selectedRow];
	if(oldIndex<MAX_ROWS)
		[self selectRow:0];
	else
	{
		[self selectRow:oldIndex-MAX_ROWS+1];
		[[self theTableView] scrollRowToVisible:[theTableView selectedRow]];
	}
	
}
- (void)keyDown:(NSEvent*)anEvent
{
	NSString* aString = [anEvent characters];
	unichar key       = 0;
	if([aString length] == 1)
	{
		key = [aString characterAtIndex:0];
		if(key == NSBackspaceCharacter || key == NSDeleteCharacter)
		{
			[mutablePrefix deleteCharactersInRange:NSMakeRange([mutablePrefix length]-1,1)];
			[self filter];
			//[self close];
		}
		else if(key == NSUpArrowFunctionKey || key == NSDownArrowFunctionKey)
		{
			; // we need to catch this since an empty tableView passes the event on here.
		}
		else if (key == NSPageUpFunctionKey || key == NSPageDownFunctionKey)
		{
			; // we need to catch this since an empty tableView passes the event on here.
		}
		else if(key == NSCarriageReturnCharacter)
		{
			[self completeAndInsertSnippet:nil];
			//[self close];
		}
		else if([aString isEqualToString:@"\t"])
		{
			if([filtered count] == 1)
				[self completeAndInsertSnippet:nil];
			else
				[self tab];
		}
		else
		{
			//[self interpretKeyEvents:[NSArray arrayWithObject:anEvent]];
			[mutablePrefix appendString:aString];
			//[mutablePrefix retain];
			//[self writeToTM:aString asSnippet:NO];
			[self filter];
		}
	}
}

- (NSString*)executeShellCommand:(NSString*)command WithDictionary:(NSDictionary*)dict
{
	NSString* stdIn = [dict description];
	NSTask* task = [[ NSTask alloc ] init ];
	[task setLaunchPath: @"/bin/sh"];
	NSArray *arguments;
	arguments = [NSArray arrayWithObjects:@"-c", command, nil];
	[task setArguments: arguments];
	[task setStandardInput:[[NSPipe alloc ] init]];
	NSPipe *pipe;
	pipe = [NSPipe pipe];
	[task setStandardOutput: pipe];
	NSFileHandle* taskInput = [[task standardInput] fileHandleForWriting ];

	//const char* cStringToSendToTask = [ stdIn UTF8String ];

	[taskInput writeString:stdIn];
	[taskInput closeFile];

	NSFileHandle* taskOutput;
	taskOutput = [pipe fileHandleForReading];

	[task launch];

	NSData *data;
	data = [taskOutput readDataToEndOfFile];
	NSString* r = [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding];
	return [r autorelease];
}

- (void)writeToTM:(NSString*)string asSnippet:(BOOL)snippet
{
	id textView = nil;
	if(snippet && (textView = [NSApp targetForAction:@selector(insertSnippetWithOptions:)]))
		[textView insertSnippetWithOptions:[NSDictionary dictionaryWithObjectsAndKeys:string, @"content",nil]];
	else if(textView = [NSApp targetForAction:@selector(insertText:)])
		[textView insertText:string];
}

- (NSArray*)filtered
{
    return filtered;
}

- (void)setFiltered:(NSArray*)aValue
{
	[aValue retain];
	[filtered release];
	filtered = aValue;
	[theTableView reloadData];
}

- (void)dealloc
{
	[staticPrefix release];
	[mutablePrefix release];
	[suggestions release];
	[shell release];
	[super dealloc];
}
@end
