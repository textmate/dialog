@interface NSObject (OakTextView)
- (NSPoint)positionForWindowUnderCaret;
@end

@interface TextMate : NSObject
+ (void)insertText:(NSString*)text asSnippet:(BOOL)asSnippet;
@end
