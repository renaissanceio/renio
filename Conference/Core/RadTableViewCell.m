//
//  RadTableViewCell.m
//  #renio
//
//  Created by Tim Burks on 11/9/13.
//  Copyright (c) 2013 Radtastical Inc. All rights reserved.
//

#import "RadTableViewCell.h"
#import "RadStyleManager.h"
#import "RadTableViewController.h"

@interface MapAnnotation : NSObject <MKAnnotation>
@property(nonatomic, assign) CLLocationCoordinate2D coordinate;
@property(nonatomic, copy) NSString *title;
@property(nonatomic, copy) NSString *subtitle;
@property(nonatomic) NSMutableDictionary *dictionary;
+ (MapAnnotation *) annotationWithDictionary:(NSMutableDictionary *) dictionary;
@end

@implementation MapAnnotation

+ (id)annotationWithDictionary:(NSMutableDictionary *)d {
	return [[[self class] alloc] initWithDictionary:d];
}

- (id)initWithDictionary:(NSMutableDictionary *)d {
	self = [super init];
	if(nil != self) {
		self.dictionary = d;
		id name = [d objectForKey:@"name"];
		self.title = name ? name : @"";
		self.subtitle = @"";
		CLLocation *location = [[CLLocation alloc] initWithLatitude:[[d objectForKey:@"latitude"] floatValue]
                                                          longitude:[[d objectForKey:@"longitude"] floatValue]];
		self.coordinate = location.coordinate;
	}
	return self;
}

@end

@interface RadTableViewCell () <MKMapViewDelegate>

@end

@implementation RadTableViewCell

- (void) resetWithIndexPath:(NSIndexPath *)indexPath controller:(RadTableViewController *)controller
{
    self.textLabel.numberOfLines = 0;
    self.imageView.image = nil;
    self.indexPath = indexPath;
    self.controller = controller;
    if (self.textView) {
        [self.textView removeFromSuperview];
        self.textView = nil;
    }
    if (self.slider) {
        [self.slider removeFromSuperview];
        self.slider = nil;
    }
    if (self.rightSideLabel) {
        [self.rightSideLabel removeFromSuperview];
        self.rightSideLabel = nil;
    }
}

- (void) layoutSubviews
{
    [super layoutSubviews];
    
    CGFloat sideMargin = 15;
    
    id mapInfo = [self.contents objectForKey:@"map"];
    if (mapInfo) {
        CGFloat w = self.bounds.size.width - 2*15;
        CGSize mapSize = CGSizeMake(w, 0.4*w);
        self.mapView = [[MKMapView alloc] initWithFrame:CGRectMake(sideMargin,0,mapSize.width,mapSize.height)];
        self.mapView.userInteractionEnabled = NO;
        [self addSubview:self.mapView];
        // adjust the text label to match.
        CGRect textLabelFrame = self.textLabel.frame;
        
        textLabelFrame.origin.x = sideMargin;
        textLabelFrame.size.width = self.bounds.size.width - 2*sideMargin;
        textLabelFrame.origin.y = mapSize.height;
        textLabelFrame.size.height = MAX(self.bounds.size.height - mapSize.height,1);
        self.textLabel.frame = textLabelFrame;
        CGFloat span = 0.01;
        MKCoordinateRegion region;
        region.center.latitude = [[mapInfo objectForKey:@"latitude"] doubleValue] + 0.20*span;
        region.center.longitude = [[mapInfo objectForKey:@"longitude"] doubleValue];
        region.span.latitudeDelta = span;
        region.span.longitudeDelta = span;
        
        [self.mapView setRegion:region animated:NO];
        //[self.mapView removeAnnotations:mapView.annotations];
        MapAnnotation *annotation = [MapAnnotation annotationWithDictionary:mapInfo];
        [self.mapView addAnnotation:annotation];
        [self.mapView selectAnnotation:annotation animated:NO];
        self.mapView.delegate = self;
    }
    
    id input = [self.contents objectForKey:@"input"];
    if (input && [input isKindOfClass:[NSDictionary class]]) {
        id type = [[input objectForKey:@"type"] lowercaseString];
        CGFloat offset = 0;
        if ([type isEqualToString:@"rating"]) {
            CGRect sliderFrame = self.bounds;
            sliderFrame.origin.x = sideMargin;
            sliderFrame.size.width -= 2*sideMargin;
            self.slider.frame = sliderFrame;
            offset = 40;
        } else if ([type isEqualToString:@"text"]) {
            CGRect textViewFrame = self.bounds;
            textViewFrame.origin.x = sideMargin;
            textViewFrame.size.width -= 2*sideMargin;
            self.textView.frame = textViewFrame;
            [self addSubview:self.textView];
            offset = 200;
        } else if ([type isEqualToString:@"field"]) {
            CGRect textFieldFrame = self.bounds;
            textFieldFrame.origin.x = sideMargin;
            textFieldFrame.size.width -= 2*sideMargin;
            self.textField.frame = textFieldFrame;
            [self addSubview:self.textField];
            offset = 20;
        }
        // adjust the text label to match.
        CGRect textLabelFrame = self.textLabel.frame;
        
        textLabelFrame.origin.x = sideMargin;
        textLabelFrame.size.width = self.bounds.size.width - 2*sideMargin;
        textLabelFrame.origin.y = offset;
        textLabelFrame.size.height = MAX(self.bounds.size.height - offset,1);
        self.textLabel.frame = textLabelFrame;
    }
    
    id rightMarkdown = [self.contents objectForKey:@"right-markdown"];
    if (rightMarkdown) {        
        NSAttributedString *attributedText = [[RadStyleManager sharedInstance]
                                              attributedStringForMarkdown:rightMarkdown withAttributesNamed:@"right"];
        CGRect rightSideFrame;
        rightSideFrame.origin.x = sideMargin;
        rightSideFrame.origin.y = 0;
        rightSideFrame.size.width = self.bounds.size.width - 2*sideMargin;
        rightSideFrame.size.height = self.bounds.size.height;
        if (!self.rightSideLabel) {
            self.rightSideLabel = [[UILabel alloc] initWithFrame:rightSideFrame];
            [self addSubview:self.rightSideLabel];
        }  else {
            self.rightSideLabel.frame = rightSideFrame;
        }
        self.rightSideLabel.attributedText = attributedText;
    }
    
    id imageInfo = [self.contents objectForKey:@"image"];
    if (imageInfo && [imageInfo isKindOfClass:[NSDictionary class]]) {
        self.imageView.contentMode = UIViewContentModeScaleAspectFill;
        id position = [imageInfo objectForKey:@"position"];
        
        
        if (!position || [position isEqualToString:@"left"]) {
            // The following code keeps the image size constant as the table row height varies.
            // Without it, the image view gets wider as the row height increases.
            // If there is no image, the image view's frame will have zero size and we can skip this.
            CGFloat imageSize = 60*[RadStyleManager sharedInstance].deviceImageScale;
            
            // set the image view to a fixed size, centered vertically.
            CGRect imageViewFrame = self.imageView.frame;
            imageViewFrame.origin.x = sideMargin;
            imageViewFrame.origin.y = 0.5*(self.bounds.size.height - imageSize);
            imageViewFrame.size.width = imageSize;
            imageViewFrame.size.height = imageSize;
            self.imageView.frame = imageViewFrame;
            
            // adjust the text label to match.
            CGRect textLabelFrame = self.textLabel.frame;
            CGFloat rightEdge = textLabelFrame.origin.x+textLabelFrame.size.width;
            textLabelFrame.origin.x = sideMargin+imageSize+sideMargin;
            textLabelFrame.size.width = rightEdge - sideMargin - imageSize;
            self.textLabel.frame = textLabelFrame;
            
            // adjust the separator; this is a bit dicey since we're diving into subviews.
            UIView *separator = [[[[self subviews] objectAtIndex:0] subviews] lastObject];
            CGRect separatorFrame = separator.frame;
            if ((separatorFrame.origin.x > 0) && (separatorFrame.size.height <= 1)) {
                separatorFrame.origin.x = textLabelFrame.origin.x;
                separatorFrame.size.width = textLabelFrame.size.width;
                separator.frame = separatorFrame;
            }
            
            // self.imageView.transform = CGAffineTransformMakeRotation(((rand() % 100)-50)*0.001);
        } else if ([position isEqualToString:@"right"]) {
            CGFloat imageSize = 60*[RadStyleManager sharedInstance].deviceImageScale;
            
            CGFloat width = self.bounds.size.width;
            CGFloat rightEdge = width - sideMargin;
            CGFloat leftEdge = sideMargin;
            
            CGRect imageViewFrame = self.imageView.frame;
            imageViewFrame.origin.x = rightEdge - imageSize;
            imageViewFrame.origin.y = 0.5*(self.bounds.size.height - imageSize);
            imageViewFrame.size.width = imageSize;
            imageViewFrame.size.height = imageSize;
            self.imageView.frame = imageViewFrame;
            
            CGRect textLabelFrame = self.textLabel.frame;
            textLabelFrame.origin.x = leftEdge;
            textLabelFrame.size.width = rightEdge - imageSize - sideMargin - leftEdge;
            self.textLabel.frame = textLabelFrame;
            
            // adjust the separator; this is a bit dicey since we're diving into subviews.
            UIView *separator = [[[[self subviews] objectAtIndex:0] subviews] lastObject];
            CGRect separatorFrame = separator.frame;
            if ((separatorFrame.origin.x > 0) && (separatorFrame.size.height <= 1)) {
                separatorFrame.origin.x = textLabelFrame.origin.x;
                separatorFrame.size.width = textLabelFrame.size.width;
                separator.frame = separatorFrame;
            }
            
        } else if ([position isEqualToString:@"top"]) {
            CGRect imageViewFrame = self.imageView.frame;
            // intentionally use the smaller scale factor
            
            
            CGFloat imageSize = 290*[RadStyleManager sharedInstance].deviceTextScale;
            
            // set the image view to a fixed size, centered horizontally.
            imageViewFrame.origin.x = 0.5*(self.bounds.size.width - imageSize);
            imageViewFrame.origin.y = 5;
            imageViewFrame.size.width = imageSize;
            imageViewFrame.size.height = imageSize;
            self.imageView.frame = imageViewFrame;
            
            // adjust the text label to match.
            CGRect textLabelFrame = self.textLabel.frame;
            
            textLabelFrame.origin.x = sideMargin;
            textLabelFrame.size.width = self.bounds.size.width - 2*sideMargin;
            textLabelFrame.origin.y = imageSize;
            textLabelFrame.size.height = MAX(self.bounds.size.height - imageSize,1);
            self.textLabel.frame = textLabelFrame;
        }
    } else {
        
    }
}

- (MKAnnotationView *)mapView:(MKMapView *)mv
			viewForAnnotation:(id <MKAnnotation>)_annotation {
	MKAnnotationView *view = nil;
	if(_annotation != mv.userLocation) {
		MapAnnotation *annotation = (MapAnnotation*)_annotation;
		view = [mv dequeueReusableAnnotationViewWithIdentifier:@"custom"];
		if(nil == view) {
			view = [[MKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"custom"];
		}
	}
	return view;
}


@end

