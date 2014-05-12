//
//  KZColorPickerAlphaSlider.m
//
//  Created by Alex Restrepo on 5/11/11.
//  Copyright 2011 KZLabs http://kzlabs.me
//  All rights reserved.
//

#import "ColorRangePickerSlider.h"


@implementation ColorRangePickerSlider

- (id)initWithFrame:(CGRect)frame WithBackground:(NSString*)name
{
    imageName = name;
    return [self initWithFrame:frame];
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) 
    {
        // Initialization code
        checkerboard = [[UIImageView alloc] initWithFrame:CGRectMake(18, 6,
                                                                frame.size.width - 36,
                                                                frame.size.height - 12)];
        checkerboard.image = [UIImage imageNamed:imageName];
        checkerboard.layer.cornerRadius = 6.0;
        checkerboard.clipsToBounds = YES;
        checkerboard.userInteractionEnabled = NO;
        [self addSubview:checkerboard];
        
		if ([self respondsToSelector:@selector(contentScaleFactor)])
			self.contentScaleFactor = [[UIScreen mainScreen] scale];
    }
    return self;
}

- (void) setFrame:(CGRect)frame
{
    [super setFrame:frame];
    [checkerboard setFrame:CGRectMake(18, 6, frame.size.width - 36, frame.size.height - 12)];
    self.value = self.value;
}
@end
