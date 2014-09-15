static NSString* const kDialogServerConnectionName = @"com.macromates.dialog";

@protocol DialogServerProtocol
- (void)connectFromClientWithOptions:(id)anArgument;
@end

#ifndef sizeofA
#define sizeofA(a) (sizeof(a)/sizeof(a[0]))
#endif
