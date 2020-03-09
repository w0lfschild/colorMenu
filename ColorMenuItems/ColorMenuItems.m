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

@interface NSMenuExtraView : NSView
{
    NSMenu *_menu;
    NSImage *_image;
    NSImage *_alternateImage;
}

@property(retain, nonatomic) NSImage *alternateImage; // @synthesize alternateImage=_alternateImage;
@property(retain, nonatomic) NSImage *image; // @synthesize image=_image;
- (void)mouseDown:(id)arg1;
- (void)drawRect:(struct CGRect)arg1;
- (void)setMenu:(id)arg1;
- (id)initWithFrame:(struct CGRect)arg1 menuExtra:(id)arg2;

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
    JSRollCall *rc = [JSRollCall new];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.05 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [rc allObjectsOfClassName:@"NSStatusItem" includeSubclass:YES performBlock:^(id obj) {
//            NSLog(@"ROLLCALL: %@", [obj className]);

            NSStatusItem *myStatusItem = (NSStatusItem*)obj;
            if (@available(macOS 10.14, *)) {
                NSButton *button = myStatusItem.button;
                button.contentTintColor = NSColor.controlAccentColor;

                // Legacy menu item :(
                if (!button) {
                    static dispatch_once_t onceToken;
                    dispatch_once(&onceToken, ^{
                        ZKSwizzle(BIGD, NSImageCell);
                        ZKSwizzle(LILD, NSCell);
                        ZKSwizzle(LILV, NSTextFieldCell);
                        ZKSwizzle(LILA, CLKView);
                    });
                    
                    NSView *v = [myStatusItem performSelector:@selector(view)];
//                    NSLog(@"ROLLCALL: %@", myStatusItem.view);
//                    NSLog(@"ROLLCALL: %@", myStatusItem.view.subviews.firstObject.className);
                    
                    Boolean needsDisplay = false;
                    NSString *className = v.subviews.firstObject.className;
                    
                    if ([className isEqualToString:@"AppleVolumeExtraTitle"]) needsDisplay = true;
                    if ([className isEqualToString:@"BatteryViewInMenu"]) needsDisplay = true;
//                        NSView *v3 = v.subviews.firstObject;
//                        NSImage *popl = [[v3 valueForKey:@"_lastBatteryImage"] firstObject];
//                        NSImageCell *ce = [v3 valueForKey:@"_batteryImageCell"];
//                        [ce setImage:popl];
//                        NSTextFieldCell *pop1 = [v3 valueForKey:@"_batteryTextCell"];
//                        pop1.textColor = NSColor.controlAccentColor;
                    if ([className isEqualToString:@"CLKDigitalView"]) {
                        needsDisplay = true;
                        NSView *v3 = v.subviews.firstObject;
                        NSTextFieldCell *popl = [v3 valueForKey:@"cell"];
                        popl.textColor = NSColor.controlAccentColor;
                    }
                    
                    if (needsDisplay) {
                        NSView *v3 = v.subviews.firstObject;
                        [v3 needsDisplay];
                        [v3 display];
                    }
                    
                    NSImage *i = [myStatusItem performSelector:@selector(image)];
                    if (i)
                        [myStatusItem performSelector:@selector(setImage:) withObject:[[v imageRepresentation] imageTintedWithColor:NSColor.controlAccentColor]];
                }
            } else {
                // Fallback on earlier versions
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
//    NSLog(@"ROLLCALL: %@", self.target);
    NSImage *test = arg1;
    [test setTemplate:NO];
    NSImage *tinted = [test imageTintedWithColor:NSColor.controlAccentColor];
    ZKOrig(void, tinted);
}

@end

// ---------------------------------------------------------------------------------

@interface BIGD : NSCell
@end

@implementation BIGD

- (void)setImage:(id)arg1 {
//    NSLog(@"ROLLCALL: %@", self.className);
    NSImage *test = arg1;
    [test setTemplate:NO];
    NSImage *tinted = [test imageTintedWithColor:NSColor.controlAccentColor];
    ZKOrig(void, tinted);
}

@end
