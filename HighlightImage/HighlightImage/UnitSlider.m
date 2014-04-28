//
//  KZUnitSlider.m
//
//  Created by Alex Restrepo on 5/11/11.
//  Copyright 2011 KZLabs http://kzlabs.me
//  All rights reserved.
//

#import "UnitSlider.h"

@interface UnitSlider()
@property (nonatomic, retain) UIImageView *sliderKnobView;
@end

@implementation UnitSlider
@synthesize sliderKnobView;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) 
    {
        // Initialization code
		UIImageView *knob = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"colorPickerKnob.png"]];
		[self addSubview:knob];		
		self.sliderKnobView = knob;
		
		self.backgroundColor = [UIColor clearColor];
		self.userInteractionEnabled = YES;
		self.value = 0.0;
    }
    return self;
}

- (CGFloat) value
{
	return value;
}

- (void) setValue:(CGFloat)val
{	
	CGFloat max_val = MAX(MIN(val, 1.0), 0.0);
	value = max_val * 360;
    
	CGFloat x = roundf((1 - max_val) * (self.frame.size.width - 40) - self.sliderKnobView.bounds.size.width * 0.5) + self.sliderKnobView.bounds.size.width * 0.5;
	CGFloat y = roundf((self.bounds.size.height - self.sliderKnobView.bounds.size.height) * 0.5) + self.sliderKnobView.bounds.size.height * 0.5;
    
    x += 20;
    
	self.sliderKnobView.center = CGPointMake(x, y);
}

- (void) mapPointToValue:(CGPoint)point
{
	CGFloat val = 1 - ((point.x - 20) / (self.frame.size.width - 40));
	self.value = val;
}

- (BOOL)beginTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event
{
	[self mapPointToValue:[touch locationInView:self]];
	return YES;
}

- (BOOL)continueTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event
{
	[self mapPointToValue:[touch locationInView:self]];
	return YES;
}

- (void)endTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event
{
	[self continueTrackingWithTouch:touch withEvent:event];
    [self sendActionsForControlEvents:UIControlEventValueChanged];
}

- (void)didAddSubview:(UIView *)subview
{
    [self bringSubviewToFront:sliderKnobView];
}
@end
