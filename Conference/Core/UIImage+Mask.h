//
//  UIImage+Mask.h
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
