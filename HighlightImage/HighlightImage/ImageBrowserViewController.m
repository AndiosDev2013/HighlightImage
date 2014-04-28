//
//  ImageBrowserViewController.m
//  HighlightImage
//
//  Created by JiangJian on 20/4/14.
//  Copyright (c) 2014 hanayonghe. All rights reserved.
//

#import "ImageBrowserViewController.h"
#import "ResultViewController.h"

#define segmentSize    10
#define yellowLimitLow  20
#define yellowLimitHigh 88
#define blueLimitLow    120
#define blueLimitHigh   240
#define satureLimitLow  0.2
#define satureLimitHigh 0.45
@interface ImageBrowserViewController ()

@end

@implementation ImageBrowserViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (UIImage *)convertImageToGrayScale:(UIImage *)image {
    // Create image rectangle with current image width/height
    CGRect imageRect = CGRectMake(0, 0, image.size.width, image.size.height);
    
    // Grayscale color space
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceGray();
    
    // Create bitmap content with current image size and grayscale colorspace
    CGContextRef context = CGBitmapContextCreate(nil, image.size.width, image.size.height, 8, 0, colorSpace, kCGImageAlphaNone);
    
    // Draw image into current context, with specified rectangle
    // using previously defined context (with grayscale colorspace)
    CGContextDrawImage(context, imageRect, [image CGImage]);
    
    // Create bitmap image info from pixel data in current context
    CGImageRef imageRef = CGBitmapContextCreateImage(context);
    
    // Create a new UIImage object
    UIImage *newImage = [UIImage imageWithCGImage:imageRef];
    
    // Release colorspace, context and bitmap information
    CGColorSpaceRelease(colorSpace);
    CGContextRelease(context);
    CFRelease(imageRef);
    
    // Return the new grayscale image
    return newImage;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    // set real imageview
    if (self.realImage != NULL) {
        RealImageView.image = self.realImage;
        CGRect topViewRect = RealImageView.bounds;
        
        blueAngVal1 = 50;
        blueAngVal2 = 360;
        yellowAngVal1 = 70;
        yellowAngVal2 = 360;
        brightLimitVal = 0;
        
        //Show color picker slider
        blueAng1 = [[ColorRangePickerSlider alloc] initWithFrame:CGRectMake(20,topViewRect.size.height + 102 , topViewRect.size.width, 40) WithBackground:@"blue.png"];
        blueAng1.value = 1.0 - blueAngVal1 / 360.0f;
        [blueAng1 addTarget:self action:@selector(blueAngleFirstChanged:) forControlEvents:UIControlEventValueChanged];
        
        blueAng2 = [[ColorRangePickerSlider alloc] initWithFrame:CGRectMake(20,topViewRect.size.height + 152 , topViewRect.size.width, 40) WithBackground:@"blue.png"];
        blueAng2.value = 1.0 - blueAngVal2 / 360.0f;
        [blueAng2 addTarget:self action:@selector(blueAngleSecondChanged:) forControlEvents:UIControlEventValueChanged];
        
        yellowAng1 = [[ColorRangePickerSlider alloc] initWithFrame:CGRectMake(748 - topViewRect.size.width,topViewRect.size.height + 87 , topViewRect.size.width, 40) WithBackground:@"yellow.png"];
        yellowAng1.value = 1.0 - yellowAngVal1 / 360.0f;
        [yellowAng1 addTarget:self action:@selector(yellowAngleFirstChanged:) forControlEvents:UIControlEventValueChanged];
        
        yellowAng2 = [[ColorRangePickerSlider alloc] initWithFrame:CGRectMake(748 - topViewRect.size.width,topViewRect.size.height + 127 , topViewRect.size.width, 40) WithBackground:@"yellow.png"];
        yellowAng2.value = 1.0 - yellowAngVal2 / 360.0f;
        [yellowAng2 addTarget:self action:@selector(yellowAngleSecondChanged:) forControlEvents:UIControlEventValueChanged];
        
        brightBar = [[ColorRangePickerSlider alloc] initWithFrame:CGRectMake(748 - topViewRect.size.width,topViewRect.size.height + 167 , topViewRect.size.width, 40) WithBackground:@"brightness.png"];
        brightBar.value = 1.0 - brightLimitVal / 360.0f;
        [brightBar addTarget:self action:@selector(brightChanged:) forControlEvents:UIControlEventValueChanged];
        
        [self.view addSubview:blueAng1];
        [self.view addSubview:blueAng2];
        [self.view addSubview:yellowAng1];
        [self.view addSubview:yellowAng2];
        [self.view addSubview:brightBar];
        
        //Store org image
        ciOrgImage = [[CIImage alloc] initWithCGImage:self.realImage.CGImage];
        
        //Store grayscale as background
        UIImage *grayscaleImage = [self convertImageToGrayScale:self.realImage];
        backImage = [[CIImage alloc] initWithImage:grayscaleImage];
        
        //Show gray-scale background image
        GrayScaledImageView.image = [UIImage imageWithCGImage:grayscaleImage.CGImage];
        
        NSUInteger width = CGImageGetWidth(self.realImage.CGImage);
        NSUInteger height = CGImageGetHeight(self.realImage.CGImage);
        
        NSLog(@"%lu::%lu", (unsigned long)width, (unsigned long)height);
        
        orgRawData = CGDataProviderCopyData(CGImageGetDataProvider(self.realImage.CGImage));
        
        if (drawingData != nil)
            free(drawingData);
        drawingData = malloc(width * height * sizeof(uint32_t));
        brightnessData = nil;
        
        [self calcBrightness];
        [self updateBlueResultView];
        [self updateYellowResultView];
    }
}

-(void) updateBlueResultView {
    @autoreleasepool {
        float realAngVal1 = blueLimitLow + (blueAngVal1 / 360.0f) * (blueLimitHigh - blueLimitLow);
        float realAngVal2 = blueLimitLow + (blueAngVal2 / 360.0f) * (blueLimitHigh - blueLimitLow);
        
        //Pick only blue and yellow colors
        CIImage *blueHighlighted = [self render:MIN(realAngVal1, realAngVal2)
                                            max:MAX(realAngVal1, realAngVal2) bright:false];
        //Merge with gray-scale background image
        CIImage *blueResult = [self mergeWithBackground:blueHighlighted background:backImage];
        
        //Show blue highlighed result image
        BlueHighligtedImageView.image = [UIImage imageWithCIImage:blueResult];
    }
}

-(void) updateYellowResultView {
    @autoreleasepool {
        float realAngVal1 = yellowLimitLow + (yellowAngVal1 / 360.0f) * (yellowLimitHigh - yellowLimitLow);
        float realAngVal2 = yellowLimitLow + (yellowAngVal2 / 360.0f) * (yellowLimitHigh - yellowLimitLow);
        
        //Pick only blue and yellow colors
        CIImage *yellowHighlighted = [self render:MIN(realAngVal1, realAngVal2)
                                              max:MAX(realAngVal1, realAngVal2) bright:true];
        
        //Merge with gray-scale background image
        CIImage *yellowResult = [self mergeWithBackground:yellowHighlighted background:backImage];
        
        //Get final result image
        CIImage *blueResult = BlueHighligtedImageView.image.CIImage;
        finalResultImage = [self mergeWithBackground:yellowHighlighted background:blueResult];
        
        //Show yellow highlighed result image
        YellowHighligtedImageView.image = [UIImage imageWithCIImage:yellowResult];
    }
}

-(CIImage *) mergeWithBackground:(CIImage*)foreground background:(CIImage *)background {
    CIFilter *filter = [CIFilter filterWithName:@"CISourceOverCompositing"];
    [filter setValue:background forKey:kCIInputBackgroundImageKey];
    [filter setValue:foreground forKey:kCIInputImageKey];
    return [filter outputImage];
}

-(void) rgbToHSV:(float*)rgb hsv:(float*)hsv
{
    float min, max, delta;
    float r = rgb[0], g = rgb[1], b = rgb[2];
    
    min = MIN( r, MIN( g, b ));
    max = MAX( r, MAX( g, b ));
    hsv[2] = max;               // v
    delta = max - min;
    if( max != 0 )
        hsv[1] = delta / max;       // s
    else {
        // r = g = b = 0        // s = 0, v is undefined
        hsv[1] = 0;
        hsv[0] = -1;
        return;
    }
    if( r == max )
        hsv[0] = ( g - b ) / delta;     // between yellow & magenta
    else if( g == max )
        hsv[0] = 2 + ( b - r ) / delta; // between cyan & yellow
    else
        hsv[0] = 4 + ( r - g ) / delta; // between magenta & cyan
    hsv[0] *= 60;               // degrees
    if( hsv[0] < 0 )
        hsv[0] += 360;
}

- (void) calcBrightness {
    float rgb[3], hsv[3];
    int segmentPosX, segmentPosY;

    NSUInteger width = CGImageGetWidth(self.realImage.CGImage);
    NSUInteger height = CGImageGetHeight(self.realImage.CGImage);
    brightnessDataWidth = width / segmentSize;
    if (width % segmentSize)
        brightnessDataWidth += 1;
    
    brightnessDataHeight = height / segmentSize;
    if (height % segmentSize)
        brightnessDataHeight += 1;
    
    brightnessData = malloc(brightnessDataWidth * brightnessDataHeight * sizeof(float));
    
    uint32_t* data = (uint32_t*)CFDataGetBytePtr(orgRawData);
    
    for (int y = 0; y < brightnessDataHeight; y++)
    {
        for (int x = 0; x < brightnessDataWidth; x++)
        {
            float *brightness = &brightnessData[y *brightnessDataWidth + x];
            *brightness = 0.0f;
            
            for (int j = 0; j < segmentSize; j++)
            {
                segmentPosY = y * segmentSize + j;
                if (segmentPosY >= height)
                    break;
                
                for (int i = 0; i < segmentSize; i++)
                {
                    segmentPosX = x * segmentSize + i;
                    if (segmentPosX >= width)
                        break;
                    
                    uint8_t* orgValues = (uint8_t*)&data[segmentPosY * width + segmentPosX];
                    rgb[0] = orgValues[0] / 255.0f;
                    rgb[1] = orgValues[1] / 255.0f;
                    rgb[2] = orgValues[2] / 255.0f;
                    
                    [self rgbToHSV:rgb hsv:hsv];
                    float brightVal = hsv[2] * 255;
                    
                    *brightness += brightVal;
                }
            }
            
            *brightness = *brightness / segmentSize / segmentSize;
        }
    }
}

- (int) checkBrightnessRangeX:(int)x withY:(int)y {
    int brightnessDataX = x / segmentSize;
    int brightnessDataY = y / segmentSize;
    
    float *brightness = &brightnessData[brightnessDataY * brightnessDataWidth + brightnessDataX];
    if (*brightness > ((brightLimitVal / 360.0f) * 255))
        return 1;
    
    return 0;
}

- (CIImage*)render:(int)minAngle max:(int)maxAngle bright:(BOOL)enable
{
    float rgb[3], hsv[3];
    
    NSUInteger width = CGImageGetWidth(self.realImage.CGImage);
    NSUInteger height = CGImageGetHeight(self.realImage.CGImage);
    
    uint32_t* data = (uint32_t*)CFDataGetBytePtr(orgRawData);
    
    for (int y = 0; y < height; y++)
    {
        for (int x = 0; x < width; x++)
        {
            uint8_t* rgbaValues = (uint8_t*)&drawingData[y * width + x];
            uint8_t* orgValues = (uint8_t*)&data[y * width + x];
            
            rgb[0] = orgValues[0] / 255.0f;
            rgb[1] = orgValues[1] / 255.0f;
            rgb[2] = orgValues[2] / 255.0f;
            [self rgbToHSV:rgb hsv:hsv];
            
            int alpha = 1;
            alpha = (hsv[0] <= minAngle || hsv[0] >= maxAngle) ? 0 : 1;
            if ((alpha == 1) && (enable == TRUE)) {
                alpha = (hsv[1] <= satureLimitLow || hsv[1] >= satureLimitHigh) ? 0 : 1;
                if (alpha == 1)
                    alpha = [self checkBrightnessRangeX:x withY:y];
            }
            
            rgbaValues[0] = 255 * alpha;
            rgbaValues[1] = orgValues[0] * alpha;
            rgbaValues[2] = orgValues[1] * alpha;
            rgbaValues[3] = orgValues[2] * alpha;
        }
    }
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    NSUInteger bytesPerPixel = 4;
    NSUInteger bytesPerRow = bytesPerPixel * width;
    NSUInteger bitsPerComponent = 8;
    CGContextRef context = CGBitmapContextCreate(drawingData, width, height,
                                                  bitsPerComponent, bytesPerRow, colorSpace,
                                                 kCGImageAlphaPremultipliedFirst);
    CGColorSpaceRelease(colorSpace);
    
    CGImageRef newCGImage = CGBitmapContextCreateImage(context);
    CIImage *newImage = [CIImage imageWithCGImage:newCGImage];
    CGImageRelease(newCGImage);
    CGContextRelease(context);
    
    return newImage;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    
    // Dispose of any resources that can be recreated.
}

-(void)viewDidUnload {
    [super viewDidUnload];
    
    if (drawingData != nil)
        free (drawingData);
    drawingData = nil;
    
    if (brightnessData != nil)
        free(brightnessData);
    brightnessData = nil;
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if (finalResultImage != NULL) {
        ResultViewController *imgResultViewCtrl = segue.destinationViewController;
        imgResultViewCtrl.resultImage = finalResultImage;
    }
}

- (void) blueAngleFirstChanged:(ColorRangePickerSlider *)slider
{
	blueAngVal1 = 360 - slider.value;
    [self updateBlueResultView];
}

- (void) blueAngleSecondChanged:(ColorRangePickerSlider *)slider
{
	blueAngVal2 = 360 - slider.value;
    [self updateBlueResultView];
}

- (void) yellowAngleFirstChanged:(ColorRangePickerSlider *)slider
{
	yellowAngVal1 = 360 - slider.value;
    [self updateYellowResultView];
}

- (void) yellowAngleSecondChanged:(ColorRangePickerSlider *)slider
{
	yellowAngVal2 = 360 - slider.value;
    [self updateYellowResultView];
}

- (void) brightChanged:(ColorRangePickerSlider *)slider
{
	brightLimitVal = 360 - slider.value;
    [self updateYellowResultView];
}
@end
