//
//  TMDNibController.h
//  Dialog2
//

@interface TMDNibController : NSObject <NSWindowDelegate>
- (id)initWithNibPath:(NSString*)aPath;
- (void)showWindowAndCenter:(BOOL)shouldCenter;

- (void)addClientFileHandle:(NSFileHandle*)aFileHandle;
- (void)updateParametersWith:(id)plist;
- (void)tearDown;

- (NSWindow*)window;
- (void)setWindow:(NSWindow*)aValue;
@end
