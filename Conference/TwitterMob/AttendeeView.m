//
//  AttendeeView.m
//  TwitterMob
//
//  Created by Aleksey Novicov on 11/23/13.
//  Copyright (c) 2013 Yodel Code LLC. All rights reserved.
//

#import "AttendeeView.h"
#import "Attendee.h"

#define MAX_SCALE			3.5
#define INFO_LABEL_WIDTH	218
#define INFO_LABEL_HEIGHT	70
#define DELTA_HEIGHT		16

@interface AttendeeView ()

@property (nonatomic, strong) UIColor *color;
@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic, assign) AttendeeRange range;

@end


@implementation AttendeeView

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
		self.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
		
        self.nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.bounds.size.width - 10, 28)];
		self.nameLabel.center = CGPointMake(self.bounds.size.width/2, self.bounds.size.height/2);
		self.nameLabel.textColor = [UIColor whiteColor];
		self.nameLabel.backgroundColor = [UIColor clearColor];
		self.nameLabel.textAlignment = NSTextAlignmentCenter;
		self.nameLabel.font = [UIFont fontWithName:@"Avenir-Roman" size:22.0];
		
		[self addSubview:self.nameLabel];
		
		self.range = AttendeeRangeVeryClose;
    }
    return self;
}

+ (Class)layerClass {
    return [CAShapeLayer class];
}

- (void)layoutSubviews {
    [self setLayerProperties];
	
	if (self.pulseEnabled)
		[self attachAnimations];
}

- (void)setLayerProperties {
    CAShapeLayer *layer = (CAShapeLayer *)self.layer;
    layer.path = [UIBezierPath bezierPathWithOvalInRect:self.bounds].CGPath;
    layer.fillColor = self.color.CGColor;
}

- (void)update {
	self.range = self.attendee.range;
	self.color = self.attendee.fillColor;
	
	if (!self.attendee.twitterID) {
		self.nameLabel.text = self.attendee.peripheral.name;
	}
	else {
		self.nameLabel.text = self.attendee.twitterID;
	}
}

- (void)offsetNameLabel {
	self.nameLabel.center = CGPointMake(self.bounds.size.width/2, self.bounds.size.height/2-DELTA_HEIGHT);
}

- (void)centerNameLabel {
	self.nameLabel.center = CGPointMake(self.bounds.size.width/2, self.bounds.size.height/2);
}

#pragma mark - Properties

- (void)setAttendee:(Attendee *)attendee {
	_attendee = attendee;
	[self update];
}

- (void)setColor:(UIColor *)color {
	_color = color;
	[self setNeedsLayout];
}

- (void)setRange:(AttendeeRange)range {
	if (_range != range) {
		_range = range;
		
		CGFloat scale;
		
		switch (range) {
			case AttendeeRangeVeryClose:
				scale = 1.0;
				break;
				
			case AttendeeRangeClose:
				scale = 0.9;
				break;
				
			case AttendeeRangeNearby:
				scale = 0.8;
				break;
				
			case AttendeeRangeFar:
				scale = 0.7;
				break;
				
			case AttendeeRangeVeryFar:
				scale = 0.6;
				break;
		}
		
		[UIView animateWithDuration:0.4 animations:^{
			self.transform = CGAffineTransformMakeScale(scale, scale);
			
			if (scale == MAX_SCALE) {
				self.nameLabel.alpha = 0.0;
			}
			else {
				self.nameLabel.alpha = 1.0;
			}
		}];
	}
}

#pragma mark - PulseView

- (void)attachAnimations {
    [self attachPathAnimation];
    [self attachColorAnimationWithAlpha:0.8];
}

- (void)attachPathAnimation {
    CABasicAnimation *animation = [self animationWithKeyPath:@"path"];
    animation.toValue = (__bridge id)[UIBezierPath bezierPathWithOvalInRect:CGRectInset(self.bounds, 4, 4)].CGPath;
    animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    [self.layer addAnimation:animation forKey:animation.keyPath];
}

- (void)attachColorAnimationWithAlpha:(CGFloat)alpha {
    CABasicAnimation *animation = [self animationWithKeyPath:@"fillColor"];
    animation.fromValue = (__bridge id)[self.color colorWithAlphaComponent:alpha].CGColor;
    [self.layer addAnimation:animation forKey:animation.keyPath];
}

- (CABasicAnimation *)animationWithKeyPath:(NSString *)keyPath {
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:keyPath];
    animation.autoreverses = YES;
    animation.repeatCount = HUGE_VALF;
    animation.duration = 1;
    return animation;
}

@end
