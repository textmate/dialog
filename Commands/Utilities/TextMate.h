@interface NSObject (OakTextView)
- (NSPoint)positionForWindowUnderCaret;
- (id)insertSnippetWithOptions:(NSDictionary*)options;
@end

@interface TextMate : NSObject
+ (void)insertText:(NSString*)text asSnippet:(BOOL)asSnippet;
@end
