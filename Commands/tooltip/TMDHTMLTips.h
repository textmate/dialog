//
//  TMDIncrementalPopUpMenu.h
//
//  Created by Ciarán Walsh on 2007-08-19.
//

#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>

@interface TMDHTMLTip : NSWindow
+ (void)showWithContent:(NSString*)content atLocation:(NSPoint)point transparent:(BOOL)transparent;
@end
