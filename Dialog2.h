#ifndef _DIALOG_H_
#define _DIALOG_H_

#define DialogServerConnectionName @"com.macromates.dialog"

@protocol DialogServerProtocol
- (void)connectFromClientWithOptions:(id)anArgument;
@end

#ifndef enumerate
#define enumerate(container,var) for(NSEnumerator* _enumerator = [container objectEnumerator]; var = [_enumerator nextObject]; )
#endif

#ifndef sizeofA
#define sizeofA(a) (sizeof(a)/sizeof(a[0]))
#endif

#define ErrorAndReturn(message) while(1){[proxy writeStringToError:@"Error: " message "\n"];return;};

#endif /* _DIALOG_H_ */
