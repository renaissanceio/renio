//
//  UIImage+Mask.m
//  #renio
//
//  Created by Tim Burks on 11/6/13.
//  Copyright (c) 2013 Radtastical Inc Inc. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import "UIImage+Mask.h"

@implementation UIImage (Mask)

// Returns a copy of the image masked with a specified shape and sized as specified.
- (UIImage *)rad_maskImageWithShape:(NSString *) shape
                               size:(CGSize) size {
    
    // Create a context where we'll draw the desired image
    CGContextRef context = CGBitmapContextCreate(NULL,
                                                 size.width,
                                                 size.height,
                                                 8,
                                                 0,
                                                 CGImageGetColorSpace(self.CGImage),
                                                 kCGBitmapByteOrderDefault | kCGImageAlphaPremultipliedFirst);
    
    // Draw the image masked with the desired shape.
    CGPathRef path = [self copy_rad_PathWithShape:shape size:size];
    CGImageRef maskImageRef = [self copy_rad_borderMaskWithPath:path size:size];
    CGContextSaveGState(context);
    CGContextClipToMask(context,
                        CGRectMake(0,0,size.width,size.height),
                        maskImageRef);
    CGContextDrawImage(context, CGRectMake(0,0,size.width,size.height), self.CGImage);
    CGContextRestoreGState(context);
    
    // Draw the mask shape as the image border.
    CGContextAddPath(context, path);
    CGContextSetStrokeColorWithColor(context, [[UIColor lightGrayColor] CGColor]);
    CGContextStrokePath(context);
    
    // Get the image from the context.
    CGImageRef imageRef = CGBitmapContextCreateImage(context);
    UIImage *image = [UIImage imageWithCGImage:imageRef];
    
    // Clean up.
    CGPathRelease(path);
    CGContextRelease(context);
    CGImageRelease(imageRef);
    CGImageRelease(maskImageRef);
    
    return image;
}

#pragma mark -
#pragma mark Private helper methods

- (CGPathRef) copy_rad_PathWithShape:(NSString *) shape
                                size:(CGSize)size {
    
    CGRect insetRect = CGRectMake(0,0,size.width,size.height);
    CGSize insetSize = insetRect.size;
    CGFloat x0 = insetRect.origin.x;
    CGFloat y0 = insetRect.origin.y;
    
    if ([shape isEqualToString:@"circle"]) {
        CGMutablePathRef path = CGPathCreateMutable();
        CGPathAddEllipseInRect(path, &CGAffineTransformIdentity, insetRect);
        return path;
    } else if ([shape isEqualToString:@"hexagon"]) {
        CGMutablePathRef path = CGPathCreateMutable();
        // CGFloat hInset = insetSize.width*0.5*tan(30.0/180.0*M_PI);
        CGFloat hInset = 0.22 * insetSize.width;
        CGPathMoveToPoint   (path, &CGAffineTransformIdentity, x0+hInset,                 y0);
        CGPathAddLineToPoint(path, &CGAffineTransformIdentity, x0+insetSize.width-hInset, y0);
        CGPathAddLineToPoint(path, &CGAffineTransformIdentity, x0+insetSize.width,        y0+0.5*insetSize.height);
        CGPathAddLineToPoint(path, &CGAffineTransformIdentity, x0+insetSize.width-hInset, y0+insetSize.height);
        CGPathAddLineToPoint(path, &CGAffineTransformIdentity, x0+hInset,                 y0+insetSize.height);
        CGPathAddLineToPoint(path, &CGAffineTransformIdentity, x0,                        y0+0.5*insetSize.height);
        CGPathCloseSubpath(path);
        return path;
    } else if ([shape isEqualToString:@"octagon"]) {
        CGMutablePathRef path = CGPathCreateMutable();
        CGFloat hInset = insetSize.width * 0.28;
        CGFloat vInset = insetSize.height * 0.28;
        CGPathMoveToPoint   (path, &CGAffineTransformIdentity, x0+hInset,                 y0);
        CGPathAddLineToPoint(path, &CGAffineTransformIdentity, x0+insetSize.width-hInset, y0);
        CGPathAddLineToPoint(path, &CGAffineTransformIdentity, x0+insetSize.width,        y0+vInset);
        CGPathAddLineToPoint(path, &CGAffineTransformIdentity, x0+insetSize.width,        y0+insetSize.height-vInset);
        CGPathAddLineToPoint(path, &CGAffineTransformIdentity, x0+insetSize.width-hInset, y0+insetSize.height);
        CGPathAddLineToPoint(path, &CGAffineTransformIdentity, x0+hInset,                 y0+insetSize.height);
        CGPathAddLineToPoint(path, &CGAffineTransformIdentity, x0,                        y0+insetSize.height-vInset);
        CGPathAddLineToPoint(path, &CGAffineTransformIdentity, x0,                        y0+vInset);
        CGPathCloseSubpath(path);
        return path;
    } else if ([shape isEqualToString:@"triangle"]) {
        CGMutablePathRef path = CGPathCreateMutable();
        CGPathMoveToPoint   (path, &CGAffineTransformIdentity, x0,                     y0);
        CGPathAddLineToPoint(path, &CGAffineTransformIdentity, x0+insetSize.width,     y0);
        CGPathAddLineToPoint(path, &CGAffineTransformIdentity, x0+0.5*insetSize.width, y0+insetSize.height);
        CGPathCloseSubpath(path);
        return path;
    } else {
        CGMutablePathRef path = CGPathCreateMutable();
        CGPathAddRect(path, &CGAffineTransformIdentity, insetRect);
        return path;
    }
}

// Creates a mask that makes the outer edges transparent and everything else opaque
// The size must include the entire mask (opaque part + transparent border)
// The caller is responsible for releasing the returned reference by calling CGImageRelease
- (CGImageRef) copy_rad_borderMaskWithPath:(CGPathRef) path size:(CGSize) size{
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceGray();
    
    // Build a context that's the same dimensions as the new size
    CGContextRef maskContext = CGBitmapContextCreate(NULL,
                                                     size.width,
                                                     size.height,
                                                     8, // 8-bit grayscale
                                                     0,
                                                     colorSpace,
                                                     kCGBitmapByteOrderDefault | kCGImageAlphaNone);
    
    // Start with a mask that's entirely transparent
    CGContextSetFillColorWithColor(maskContext, [UIColor blackColor].CGColor);
    CGContextFillRect(maskContext, CGRectMake(0, 0, size.width, size.height));
    
    // Make the inner part (within the border) opaque
    CGContextSetFillColorWithColor(maskContext, [UIColor whiteColor].CGColor);
    
    CGContextAddPath(maskContext, path);
    CGContextFillPath(maskContext);
    
    // Get an image of the context
    CGImageRef maskImageRef = CGBitmapContextCreateImage(maskContext);
    
    // Clean up
    CGContextRelease(maskContext);
    CGColorSpaceRelease(colorSpace);
    
    return maskImageRef;
}


+ (UIImage *) solidImageWithColor:(UIColor *) color size: (CGSize) size {
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    CGContextRef bitmapContext =
    CGBitmapContextCreate (NULL,
                           (int) size.width,
                           (int) size.height,
                           8, 0,
                           colorSpace,
                           (CGBitmapInfo) kCGImageAlphaPremultipliedFirst);
    if (!bitmapContext) {
        CGColorSpaceRelease(colorSpace);
        return nil;
    }
	
    CGContextSetFillColorWithColor(bitmapContext, [color CGColor]);
    CGContextFillRect(bitmapContext, CGRectMake(0, 0,
                                                size.width, size.height));
    
	
    // Convert the context into a CGImageRef and release the context
    CGImageRef theCGImage=CGBitmapContextCreateImage(bitmapContext);
    CGContextRelease(bitmapContext);
	
    // Convert the CGImageRef into a UIImage and release the CGImageRef
    UIImage *image = [UIImage imageWithCGImage:theCGImage];
    CGImageRelease(theCGImage);
    
    CGColorSpaceRelease(colorSpace);
	
    return image;
}

+ (UIImage *) rad_solidShape:(NSString *) shape
                     ofColor:(UIColor *) color
                        size:(CGSize) size
{
    UIImage *solidImage = [UIImage solidImageWithColor:color size:size];
    return [solidImage rad_maskImageWithShape:shape size:size];
}

+ (UIImage *) rad_imageWithAttributedString:(NSAttributedString *) attributedString size: (CGSize) size {
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    CGContextRef bitmapContext =
    CGBitmapContextCreate (NULL,
                           (int) size.width,
                           (int) size.height,
                           8, 0,
                           colorSpace,
                           (CGBitmapInfo) kCGImageAlphaPremultipliedFirst);
    if (!bitmapContext) {
        CGColorSpaceRelease(colorSpace);
        return nil;
    }
	
    CGContextSetFillColorWithColor(bitmapContext, [[UIColor yellowColor] CGColor]);
    CGContextFillRect(bitmapContext, CGRectMake(0, 0, size.width, size.height));
    
	
    // Convert the context into a CGImageRef and release the context
    CGImageRef theCGImage=CGBitmapContextCreateImage(bitmapContext);
    CGContextRelease(bitmapContext);
	
    // Convert the CGImageRef into a UIImage and release the CGImageRef
    UIImage *image = [UIImage imageWithCGImage:theCGImage];
    CGImageRelease(theCGImage);
    
    CGColorSpaceRelease(colorSpace);
	
    return image;
}


@end
