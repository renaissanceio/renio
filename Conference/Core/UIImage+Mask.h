//
//  UIImage+Mask.h
//  #renio
//
//  Created by Tim Burks on 11/6/13.
//  Copyright (c) 2013 Radtastical Inc Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (Mask)

- (UIImage *)rad_maskImageWithShape:(NSString *) shape
                               size:(CGSize) size;

+ (UIImage *) rad_solidShape:(NSString *) shape
                     ofColor:(UIColor *) color
                        size:(CGSize) size;

+ (UIImage *) rad_imageWithAttributedString:(NSAttributedString *) attributedString
                                       size: (CGSize) size;

@end
