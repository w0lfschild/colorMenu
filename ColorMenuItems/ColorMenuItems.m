//
//  ColorMenuItems.m
//  ColorMenuItems
//
//  Created by Wolfgang Baird on 3/8/20.
//Copyright © 2020 Wolfgang Baird. All rights reserved.
//

#import "ColorMenuItems.h"
#import "JSRollCall.h"
#import <Cocoa/Cocoa.h>
#import <CoreImage/CoreImage.h>
#import "ZKSwizzle.h"

@interface ColorMenuItems()
@end

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

@implementation ColorMenuItems

+ (instancetype)sharedInstance
{
    static ColorMenuItems *plugin = nil;
    @synchronized(self) {
        if (!plugin) {
            plugin = [[self alloc] init];
        }
    }
    return plugin;
}

+ (void)load
{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
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
                        ZKSwizzle(BIGD, NSImageCell);
                        ZKSwizzle(LILD, NSCell);
                        ZKSwizzle(LILV, NSTextFieldCell);
                        ZKSwizzle(LILA, CLKView);
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

@interface LILA : NSView
@end

@implementation LILA
- (id)drawColor { return NSColor.controlAccentColor; }
@end

// ---------------------------------------------------------------------------------

@interface LILV : NSTextFieldCell
@end

@implementation LILV
- (void)setTextColor:(NSColor *)textColor { ZKOrig(void, NSColor.controlAccentColor); }
@end

// ---------------------------------------------------------------------------------

@interface LILD : NSCell
@end

@implementation LILD

- (void)setImage:(id)arg1 {
    [arg1 setTemplate:NO];
    ZKOrig(void, [arg1 imageTintedWithColor:NSColor.controlAccentColor]);
}

@end

// ---------------------------------------------------------------------------------

@interface BIGD : NSCell
@end

@implementation BIGD

- (void)setImage:(id)arg1 {
    [arg1 setTemplate:NO];
    ZKOrig(void, [arg1 imageTintedWithColor:NSColor.controlAccentColor]);
}

@end

// ---------------------------------------------------------------------------------

