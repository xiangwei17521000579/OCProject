//
//  UIColor+Category.m
//  OCProject
//
//  Created by 王祥伟 on 2023/12/5.
//

#import "UIColor+Category.h"

@implementation UIColor (Category)

+ (UIColor *)cffffff{return [self RGB:0xffffff];}
+ (UIColor *)ccccccC{return [self RGB:0xcccccc];}
+ (UIColor *)c1e1e1e{return [self RGB:0x1e1e1e];}
+ (UIColor *)c333333{return [self RGB:0x333333];}
+ (UIColor *)c505050{return [self RGB:0x505050];}
+ (UIColor *)c000000{return [self RGB:0x000000];}
+ (UIColor *)c1eb65f{return [self RGB:0x1eb65f];}
+ (UIColor *)c1296db{return [self RGB:0x1296db];}
+ (UIColor *)cbfbfbf{return [self RGB:0xbfbfbf];}




+ (UIColor *)RGB:(int)rgb{return [self RGB:rgb A:1.0];}
+ (UIColor *)RGB:(int)rgb A:(CGFloat)a{
    return [UIColor colorWithRed:((float)((rgb & 0xFF0000) >> 16))/255.0 green:((float)((rgb & 0xFF00) >> 8))/255.0 blue:((float)(rgb & 0xFF))/255.0 alpha:a];
}

- (NSString *)hexStringWithAlpha:(BOOL)withAlpha {
    CGColorRef color = self.CGColor;
    size_t count = CGColorGetNumberOfComponents(color);
    const CGFloat *components = CGColorGetComponents(color);
    static NSString *stringFormat = @"%02x%02x%02x";
    NSString *hex = nil;
    if (count == 2) {
        NSUInteger white = (NSUInteger)(components[0] * 255.0f);
        hex = [NSString stringWithFormat:stringFormat, white, white, white];
    }else if (count == 4) {
        hex = [NSString stringWithFormat:stringFormat,
               (NSUInteger)(components[0] * 255.0f),
               (NSUInteger)(components[1] * 255.0f),
               (NSUInteger)(components[2] * 255.0f)];
    }
    
    if (hex && withAlpha) {
        hex = [hex stringByAppendingFormat:@"%02lx",(unsigned long)(self.alpha * 255.0 + 0.5)];
    }
    return hex;
}

- (CGFloat)alpha{
    return CGColorGetAlpha(self.CGColor);
}

@end
