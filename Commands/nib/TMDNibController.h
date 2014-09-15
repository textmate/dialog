//
//  TMDNibController.h
//  Dialog2
//

@interface TMDNibController : NSObject <NSWindowDelegate>
@property (nonatomic) NSWindow* window;
- (id)initWithNibPath:(NSString*)aPath;
- (void)showWindowAndCenter:(BOOL)shouldCenter;

- (void)addClientFileHandle:(NSFileHandle*)aFileHandle;
- (void)updateParametersWith:(id)plist;
- (void)tearDown;
@end
