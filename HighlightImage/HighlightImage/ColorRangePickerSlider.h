//
//  KZColorPickerAlphaSlider.h
//
//  Created by Alex Restrepo on 5/11/11.
//  Copyright 2011 KZLabs http://kzlabs.me
//  All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import "UnitSlider.h"

@interface ColorRangePickerSlider : UnitSlider
{
    UIImageView *checkerboard;
    NSString *imageName;
}

- (id)initWithFrame:(CGRect)frame WithBackground:(NSString*)name;

@end
