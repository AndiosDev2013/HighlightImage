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
    UIImage *waterMarkImage;
    CIImage *ciOrgImage;
    CIImage *backImage;
    CIImage *yellowHighlighted;
    CIImage *blueHighlighted;
    CIImage *blueResult;
    
    uint32_t *drawingData;
    float *brightnessData;
    NSUInteger brightnessDataWidth, brightnessDataHeight;
    CFDataRef orgRawData;
    CFDataRef waterMarkData;
    int width, height;
    
#if 0
    float *pixelCalcData;
    float *pixelValueData;
    int *pixelAlphaData;
    int *pixelAlphaTempData;
#endif
    
    IBOutlet UIImageView *ResultImageView;
    IBOutlet UIScrollView *scrollView;
    IBOutlet UIButton *btn_send;
    IBOutlet UIButton *btn_save;
    IBOutlet UIView   *toolBar;
    IBOutlet UIView   *sliderRegion;
    
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
    bool f_showToolBar;
    bool f_animating;
    
    CGPoint curPos;
}
@property (nonatomic, retain) UIImage *realImage;

- (IBAction)onSave:(id)sender;
- (IBAction)onSend:(id)sender;

@end
