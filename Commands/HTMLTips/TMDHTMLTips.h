//
//  TMDIncrementalPopUpMenu.h
//
//  Created by Ciarán Walsh on 2007-08-19.
//  Copyright (c) 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>

#define TMD_TOOLTIP_PREFERENCES_IDENTIFIER @"TM Tooltip"

@interface TMDHTMLTips : NSWindowController
{
	WebPreferences * webPreferences;

    IBOutlet WebView *webView;
}
- (id)init;
- (void)setHTML:(NSString *)html;
- (void)sizeToContent;
- (void)fade;
@end
