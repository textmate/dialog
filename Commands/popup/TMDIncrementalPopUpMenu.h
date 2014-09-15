//
//  TMDIncrementalPopUpMenu.h
//
//  Created by Joachim Mårtensson on 2007-08-10.
//

#import <Cocoa/Cocoa.h>
#import "../../CLIProxy.h"

static NSUInteger const MAX_ROWS = 15;

@interface TMDIncrementalPopUpMenu : NSWindow<NSTableViewDataSource>
@property (nonatomic) NSPoint caretPos;
- (id)initWithItems:(NSArray*)someSuggestions alreadyTyped:(NSString*)aUserString staticPrefix:(NSString*)aStaticPrefix additionalWordCharacters:(NSString*)someAdditionalWordCharacters caseSensitive:(BOOL)isCaseSensitive writeChoiceToFileDescriptor:(NSFileHandle*)aFileDescriptor;
@end
