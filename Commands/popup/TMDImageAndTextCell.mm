#import "TMDImageAndTextCell.h"

@interface TMDImageAndTextCell ()
{
	NSImage* _image;
}
@end

@implementation TMDImageAndTextCell
- (NSImage*)image                  { return _image; }
- (void)setImage:(NSImage*)anImage { _image = anImage; }

- (id)copyWithZone:(NSZone*)zone
{
	TMDImageAndTextCell* cell = [super copyWithZone:zone];
	cell->_image = [_image copy];
	return cell;
}

- (NSRect)imageFrameWithFrame:(NSRect)aRect inControlView:(NSView*)aView
{
	aRect.size = _image.size;
	aRect.origin.y += 1;
	aRect.origin.x += 8;
	if([aView respondsToSelector:@selector(intercellSpacing)])
		aRect.origin.y -= [(NSOutlineView*)aView intercellSpacing].height / 2;
	return aRect;
}

- (NSRect)textFrameWithFrame:(NSRect)aRect inControlView:(NSView*)aView
{
	NSRect imageFrame = [self imageFrameWithFrame:aRect inControlView:aView];
	NSRect textFrame = aRect;
	textFrame.origin.x = NSMaxX(imageFrame) + 4;
	textFrame.size.width = NSMaxX(aRect) - NSMinX(textFrame);
	return textFrame;
}

- (void)editWithFrame:(NSRect)aRect inView:(NSView*)controlView editor:(NSText*)textObj delegate:(id)anObject event:(NSEvent*)theEvent
{
	[super editWithFrame:[self textFrameWithFrame:aRect inControlView:controlView] inView:controlView editor:textObj delegate:anObject event:theEvent];
}

- (void)selectWithFrame:(NSRect)aRect inView:(NSView*)controlView editor:(NSText*)textObj delegate:(id)anObject start:(NSInteger)selStart length:(NSInteger)selLength
{
	[super selectWithFrame:[self textFrameWithFrame:aRect inControlView:controlView] inView:controlView editor:textObj delegate:anObject start:selStart length:selLength];
}

- (NSRect)expansionFrameWithFrame:(NSRect)cellFrame inView:(NSView*)view
{
	NSRect frame = [super expansionFrameWithFrame:[self textFrameWithFrame:cellFrame inControlView:view] inView:view];
	frame.size.width -= _image ? [_image size].width + 3 : 0;
	return frame;
}

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView*)controlView
{
	if(_image)
	{
		NSRect imageRect = [self imageFrameWithFrame:cellFrame inControlView:controlView];
		if([self drawsBackground])
		{
			[[self backgroundColor] set];
			NSRectFill(imageRect);
		}
		[_image drawInRect:imageRect fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1 respectFlipped:YES hints:nil];
	}

	[super drawWithFrame:[self textFrameWithFrame:cellFrame inControlView:controlView] inView:controlView];
}

- (NSSize)cellSize
{
	NSSize cellSize = [super cellSize];
	cellSize.width += _image ? [_image size].width + 3 : 0;
	return cellSize;
}
@end
