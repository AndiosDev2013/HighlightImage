//
//  ImageBrowserViewController.h
//  HighlightImage
//
//  Created by JiangJian on 20/4/14.
//  Copyright (c) 2014 hanayonghe. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ColorRangePickerSlider.h"

@interface ImageBrowserViewController : UIViewController <UIImagePickerControllerDelegate>
{
    CIImage *ciOrgImage;
    CIImage *finalResultImage;
    CIImage *backImage;
    uint32_t *drawingData;
    float *brightnessData;
    NSUInteger brightnessDataWidth, brightnessDataHeight;
    CFDataRef orgRawData;
    
    IBOutlet UIImageView *RealImageView;
    IBOutlet UIImageView *GrayScaledImageView;
    IBOutlet UIImageView *BlueHighligtedImageView;
    IBOutlet UIImageView *YellowHighligtedImageView;
    
    IBOutlet UIButton *btn_next;
    IBOutlet UIButton *btn_cancel;
    
    ColorRangePickerSlider *blueAng1;
    ColorRangePickerSlider *blueAng2;
    ColorRangePickerSlider *yellowAng1;
    ColorRangePickerSlider *yellowAng2;
    ColorRangePickerSlider *brightBar;
    
    int blueAngVal1;
    int blueAngVal2;
    int yellowAngVal1;
    int yellowAngVal2;
    int brightLimitVal;
}
@property (nonatomic, retain) UIImage *realImage;
@property (nonatomic, retain) UIImage *compositeImage;

@end
