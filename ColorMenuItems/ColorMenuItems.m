//
//  ColorMenuItems.m
//  ColorMenuItems
//
//  Created by Wolfgang Baird on 3/8/20.
//  Copyright © 2020 Wolfgang Baird. All rights reserved.
//

#import "JSRollCall.h"
#import "ZKSwizzle.h"
#import <Cocoa/Cocoa.h>

// ---------------------------------------------------------------------------------

@implementation NSView (imageView)

- (NSImage *)imageRepresentation
{
  NSSize mySize = self.bounds.size;
  NSSize imgSize = NSMakeSize( mySize.width, mySize.height );
  
  NSBitmapImageRep *bir = [self bitmapImageRepForCachingDisplayInRect:[self bounds]];
  [bir setSize:imgSize];
  [self cacheDisplayInRect:[self bounds] toBitmapImageRep:bir];
  
  NSImage* image = [[NSImage alloc]initWithSize:imgSize] ;
  [image addRepresentation:bir];
  return image;
}

@end

// ---------------------------------------------------------------------------------

@implementation NSImage (tintImage)

- (NSImage *)imageTintedWithColor:(NSColor *)tint
{
    NSImage *image = [self copy];
    if (tint) {
        [image lockFocus];
        [tint set];
        NSRect imageRect = {NSZeroPoint, [image size]};
        NSRectFillUsingOperation(imageRect, NSCompositingOperationSourceAtop);
        [image unlockFocus];
    }
    return image;
}

@end

// ---------------------------------------------------------------------------------

@interface ColorMenuItems : NSObject
@end

@implementation ColorMenuItems

+ (void)load
{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.75 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [[JSRollCall new] allObjectsOfClassName:@"NSStatusItem" includeSubclass:YES performBlock:^(id obj) {
            
            // Hooked a status item
            NSStatusItem *myStatusItem = (NSStatusItem*)obj;
            
            // Make sure we're on 10.14+
            if (@available(macOS 10.14, *)) {
                
                // Try to color the statusItem button
                NSButton *button = myStatusItem.button;
                button.contentTintColor = NSColor.controlAccentColor;

                // Legacy menu item :(
                if (!button) {
                    // Do some swizzling of cells
                    static dispatch_once_t onceToken;
                    dispatch_once(&onceToken, ^{
                        ZKSwizzle(CMI_imgCellFix, NSImageCell);
                        ZKSwizzle(CMI_cellFix, NSCell);
                        ZKSwizzle(CMI_txtFLD, NSTextFieldCell);
                        ZKSwizzle(CMI_clockFix, CLKView);
                    });
                    
                    // Try to tint the statusItem image
                    NSView *statusItemView = [myStatusItem performSelector:@selector(view)];
                    NSString *className = statusItemView.subviews.firstObject.className;
                    NSImage *i = [myStatusItem performSelector:@selector(image)];
                    if (i) {
                        [myStatusItem performSelector:@selector(setImage:) withObject:[[statusItemView imageRepresentation] imageTintedWithColor:NSColor.controlAccentColor]];
                    } else {
                        // These items require we refresh the view to get an update
                        NSView *statusView = statusItemView.subviews.firstObject;
                        if ([className isEqualToString:@"CLKDigitalView"]) {
                            NSTextFieldCell *popl = [statusView valueForKey:@"cell"];
                            popl.textColor = NSColor.controlAccentColor;
                        }
                        [statusView needsDisplay];
                        [statusView display];
                    }
                }
            }
        }];
    });
}

@end

// ---------------------------------------------------------------------------------

@interface CMI_clockFix : NSView
@end

@implementation CMI_clockFix
- (id)drawColor { return NSColor.controlAccentColor; }
@end

// ---------------------------------------------------------------------------------

@interface CMI_txtFLD : NSTextFieldCell
@end

@implementation CMI_txtFLD
- (void)setTextColor:(NSColor *)textColor { ZKOrig(void, NSColor.controlAccentColor); }
@end

// ---------------------------------------------------------------------------------

@interface CMI_cellFix : NSCell
@end

@implementation CMI_cellFix

- (void)setImage:(id)arg1 {
    [arg1 setTemplate:NO];
    ZKOrig(void, [arg1 imageTintedWithColor:NSColor.controlAccentColor]);
}

@end

// ---------------------------------------------------------------------------------

@interface CMI_imgCellFix : NSCell
@end

@implementation CMI_imgCellFix

- (void)setImage:(id)arg1 {
    [arg1 setTemplate:NO];
    ZKOrig(void, [arg1 imageTintedWithColor:NSColor.controlAccentColor]);
}

@end

// ---------------------------------------------------------------------------------
