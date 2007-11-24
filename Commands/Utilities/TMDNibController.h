//
//  TMDNibController.h
//  Dialog2
//
//  Created by Ciaran Walsh on 23/11/2007.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

@interface TMDNibController : NSObject
{
	NSArray* topLevelObjects;
	NSWindow* window;
	NSMutableDictionary* parameters;
	NSMutableArray* fileHandles;
	unsigned int token;
	BOOL autoCloses;
	BOOL isRunningModal;
}
+ (TMDNibController *)controllerForToken:(NSString*)token;
+ (NSDictionary *)controllers;

- (id)initWithNibName:(NSString*)aName;
- (NSWindow*)window;
- (void)runModal;
- (void)tearDown;
- (void)showWindowAndCenter:(BOOL)shouldCenter;
- (void)setParameters:(id)someParameters;
- (void)notifyFileHandle:(NSFileHandle*)aFileHandle;
- (void)setAutoCloses:(BOOL)flag;
- (void)setWindow:(NSWindow*)aValue;
- (NSString*)token;
- (void)updateParametersWith:(id)plist;
@end
