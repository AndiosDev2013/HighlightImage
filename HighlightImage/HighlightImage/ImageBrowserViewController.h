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
    CIImage *yellowHighlighted;
    uint32_t *drawingData;
    float *brightnessData;
    NSUInteger brightnessDataWidth, brightnessDataHeight;
    CFDataRef orgRawData;
    int width, height;
    
    float *pixelCalcData;
    float *pixelValueData;
    int *pixelAlphaData;
    int *pixelAlphaTempData;
    
    IBOutlet UIImageView *RealImageView;
    IBOutlet UIImageView *GrayScaledImageView;
    IBOutlet UIImageView *BlueHighligtedImageView;
    IBOutlet UIImageView *YellowHighligtedImageView;
    
    IBOutlet UIButton *btn_next;
    IBOutlet UIButton *btn_color;
    IBOutlet UIButton *btn_color_region;
    IBOutlet UIButton *btn_color_line;
    IBOutlet UIActivityIndicatorView *activity;
    
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
    
    int mode;
}
@property (nonatomic, retain) UIImage *realImage;
@property (nonatomic, retain) UIImage *compositeImage;

-(IBAction)onColor:(id)sender;
-(IBAction)onColorRegion:(id)sender;
-(IBAction)onColorLine:(id)sender;

@end
