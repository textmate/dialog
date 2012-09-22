#import <Foundation/Foundation.h>

@interface NSObject (OakTextView)
- (NSPoint)positionForWindowUnderCaret;
@end

BOOL insert_text (NSString* someText);
BOOL insert_snippet (NSString* aSnippet);
