//
//  ImageBrowserViewController.m
//  HighlightImage
//
//  Created by JiangJian on 20/4/14.
//  Copyright (c) 2014 hanayonghe. All rights reserved.
//

#import "ImageBrowserViewController.h"
#import <MessageUI/MessageUI.h>

#define segmentSize    10
#define drawingThick   30
#define yellowLimitLow  20
#define yellowLimitHigh 88
#define blueLimitLow    120
#define blueLimitHigh   240
#define satureLimitLow  0.2
#define satureLimitHigh 0.95
#define waterMarkOffset 100

#if 0
#define intensitySegment 10
#define fillSegment      20
#define removeSegment    10

#define COLOR_MODE      1
#define REGION_MODE     2
#define LINE_MODE       3
#endif

@interface ImageBrowserViewController ()<MFMailComposeViewControllerDelegate>

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
    
    if (self.realImage != NULL) {
        blueAngVal1 = 50;
        blueAngVal2 = 360;
        yellowAngVal1 = 70;
        yellowAngVal2 = 360;
        brightLimitVal = 120;
        
        //Show color picker slider
        CGSize sliderSize = sliderRegion.frame.size;
        int sliderWidth = (sliderSize.width - 40) / 2;
        int sliderHeight = 40;
        int gapX1 = 10;
        int gapX2 = 20;
        int gapY1 = (sliderSize.height - sliderHeight * 2) / 3;
        int gapY2 = (sliderSize.height - sliderHeight * 3) / 4;
        
        blueAng1 = [[ColorRangePickerSlider alloc] initWithFrame:
                    CGRectMake(gapX1, gapY1, sliderWidth, sliderHeight) WithBackground:@"blue.png"];
        [blueAng1 addTarget:self action:@selector(blueAngleFirstChanged:) forControlEvents:UIControlEventValueChanged];
        
        blueAng2 = [[ColorRangePickerSlider alloc] initWithFrame:
                    CGRectMake(gapX1, gapY1*2+sliderHeight, sliderWidth, sliderHeight)  WithBackground:@"blue.png"];
        [blueAng2 addTarget:self action:@selector(blueAngleSecondChanged:) forControlEvents:UIControlEventValueChanged];
        
        yellowAng1 = [[ColorRangePickerSlider alloc] initWithFrame:
                      CGRectMake(gapX1+gapX2+sliderWidth, gapY2, sliderWidth, sliderHeight) WithBackground:@"yellow.png"];
        [yellowAng1 addTarget:self action:@selector(yellowAngleFirstChanged:) forControlEvents:UIControlEventValueChanged];
        
        yellowAng2 = [[ColorRangePickerSlider alloc] initWithFrame:
                      CGRectMake(gapX1+gapX2+sliderWidth, gapY2*2+sliderHeight, sliderWidth, sliderHeight)WithBackground:@"yellow.png"];
        [yellowAng2 addTarget:self action:@selector(yellowAngleSecondChanged:) forControlEvents:UIControlEventValueChanged];
        
        brightBar = [[ColorRangePickerSlider alloc] initWithFrame:
                     CGRectMake(gapX1+gapX2+sliderWidth, gapY2*3+sliderHeight*2, sliderWidth, sliderHeight)WithBackground:@"brightness.png"];
        [brightBar addTarget:self action:@selector(brightChanged:) forControlEvents:UIControlEventValueChanged];
        UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(_handlePan:)];
        
        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(_handleTouch:)];
        tapGesture.numberOfTapsRequired = 2;
        
        [sliderRegion addSubview:blueAng1];
        [sliderRegion addSubview:blueAng2];
        [sliderRegion addSubview:yellowAng1];
        [sliderRegion addSubview:yellowAng2];
        [sliderRegion addSubview:brightBar];
        [toolBar addGestureRecognizer:tapGesture];
        [ResultImageView addGestureRecognizer:panGesture];
        toolBar.alpha = 0.0f;
        
        ResultImageView.contentMode = UIViewContentModeScaleAspectFit;
        
        //Store org image
        width = (int)CGImageGetWidth(self.realImage.CGImage);
        height = (int)CGImageGetHeight(self.realImage.CGImage);
        orgRawData = CGDataProviderCopyData(CGImageGetDataProvider(self.realImage.CGImage));
        
        if (drawingData != nil)
            free(drawingData);
        drawingData = malloc(width * height * sizeof(uint32_t));
        
        if (yellowAlphaData != nil)
            free (yellowAlphaData);
        yellowAlphaData = malloc(width * height * sizeof(float));
        
        //Store watermark image data
        
        if ([[UIScreen mainScreen] respondsToSelector:@selector(displayLinkWithTarget:selector:)] &&
            ([UIScreen mainScreen].scale == 2.0))
            //Retian display
            waterMarkImage = [UIImage imageNamed:@"watermark@2x.png"];
        else
            // Non-Retian display
            waterMarkImage = [UIImage imageNamed:@"watermark.png"];
        
        waterMarkData = CGDataProviderCopyData(CGImageGetDataProvider(waterMarkImage.CGImage));
        
        [activity startAnimating];
        [self performSelector:@selector(startProcessing) withObject:nil afterDelay:0.1f];
#if 0
        if (pixelCalcData != nil)
            free (pixelCalcData);
        pixelCalcData = malloc(width * height * sizeof(float));
        
        if (pixelValueData != nil)
            free (pixelValueData);
        pixelValueData = malloc(width * height * sizeof(float));
        
        if (pixelAlphaData != nil)
            free (pixelAlphaData);
        pixelAlphaData = malloc(width * height * sizeof(int));
        
        if (pixelAlphaTempData != nil)
            free (pixelAlphaTempData);
        pixelAlphaTempData = malloc(width * height * sizeof(int));
#endif
    }
    
}

- (void) startProcessing {
    //Store grayscale as background
    UIImage *grayscaleImage = [self convertImageToGrayScale:self.realImage];
    grayData = CGDataProviderCopyData(CGImageGetDataProvider(grayscaleImage.CGImage));
    int rowbytes = CGImageGetBytesPerRow(grayscaleImage.CGImage);
    int size = CFDataGetLength(grayData);
    f_landscapeImage = false;

    if (rowbytes != grayscaleImage.size.width) {
        diffPixelCount = rowbytes - grayscaleImage.size.width;
        f_landscapeImage = true;
    }
    
    NSLog(@"%lu::%lu", (unsigned long)width, (unsigned long)height);
    
    brightnessData = nil;
    
    @autoreleasepool {
        [self calcBrightness];
        [self updateResultView];
    }
    
    [activity stopAnimating];
}

- (void) hideToolBar {
    [UIView animateWithDuration:1.0f
                          delay:0
                        options:UIViewAnimationCurveLinear
                     animations:^{
                         toolBar.alpha = 0.5f;
                         [toolBar setCenter:CGPointMake(toolBar.center.x, toolBar.center.y + toolBar.frame.size.height - 50)];
                     }
                     completion:^(BOOL finished) {
                         f_showToolBar = false;
                         f_animating = false;
                     }];
}

- (void) showToolBar {
    [UIView animateWithDuration:1.0f
                          delay:0
                        options:UIViewAnimationCurveLinear
                     animations:^{
                         toolBar.alpha = 1.0f;
                         [toolBar setCenter:CGPointMake(toolBar.center.x, toolBar.center.y - toolBar.frame.size.height + 50)];
                     }
                     completion:^(BOOL finished) {
                         f_showToolBar = true;
                         f_animating = false;
                     }];
}

-(void) updateResultView {
    float blue1 = blueLimitLow + (blueAngVal1 / 360.0f) * (blueLimitHigh - blueLimitLow);
    float blue2 = blueLimitLow + (blueAngVal2 / 360.0f) * (blueLimitHigh - blueLimitLow);
    float yellow1 = yellowLimitLow + (yellowAngVal1 / 360.0f) * (yellowLimitHigh - yellowLimitLow);
    float yellow2 = yellowLimitLow + (yellowAngVal2 / 360.0f) * (yellowLimitHigh - yellowLimitLow);
    
    //Pick only blue and yellow color
    ResultImageView.image = [self render:MIN(blue1, blue2)
                            withMaxBlue:MAX(blue1, blue2)
                            withMinYellow:MIN(yellow1, yellow2)
                            withMaxYellow:MAX(yellow1, yellow2)];
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
    float *brightness;
    
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
            brightness = &brightnessData[y *brightnessDataWidth + x];
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

- (UIImage*)render:(int)minBlue withMaxBlue:(int)maxBlue
     withMinYellow:(int)minYellow withMaxYellow:(int)maxYellow
{
    float rgb[3], hsv[3];
    uint8_t* rgbaValues;
    uint8_t* orgValues;
    uint8_t* waterMarkValues;
    
    int waterWidth = (int)CGImageGetWidth(waterMarkImage.CGImage);
    int waterHeight = (int)CGImageGetHeight(waterMarkImage.CGImage);
    uint32_t* data = (uint32_t*)CFDataGetBytePtr(orgRawData);
    uint32_t* waterData = (uint32_t*)CFDataGetBytePtr(waterMarkData);
    uint8_t* grayValues = (uint8_t*)CFDataGetBytePtr(grayData);
    int orgX, orgY, x,y;
    int alpha = 1;
    
    if ([[UIScreen mainScreen] respondsToSelector:@selector(displayLinkWithTarget:selector:)] &&
        ([UIScreen mainScreen].scale == 2.0)) {
        //Retina display
        orgX = width - waterWidth - waterMarkOffset;
        orgY = height - waterHeight - waterMarkOffset;
    } else {
        //Non-Retina display
        orgX = width - waterWidth - waterMarkOffset / 2;
        orgY = height - waterHeight - waterMarkOffset / 2;
    }

    
    memset(yellowAlphaData, 0, sizeof(width * height * sizeof(int)));
    for (y = 0; y < height; y++)
    {
        for (x = 0; x < width; x++)
        {
            rgbaValues = (uint8_t*)&drawingData[y * width + x];
            
            if ((x >= orgX) && (x < orgX + waterWidth) &&
                (y >= orgY) && (y < orgY + waterHeight)) {
                waterMarkValues = (uint8_t*)&waterData[(y-orgY) * waterWidth + (x-orgX)];
                if (waterMarkValues[3]) {
                    rgbaValues[0] = waterMarkValues[3];
                    rgbaValues[1] = waterMarkValues[0];
                    rgbaValues[2] = waterMarkValues[1];
                    rgbaValues[3] = waterMarkValues[2];
                    continue;
                }
            }

            orgValues = (uint8_t*)&data[y * width + x];
            
            rgb[0] = orgValues[0] / 255.0f;
            rgb[1] = orgValues[1] / 255.0f;
            rgb[2] = orgValues[2] / 255.0f;
            [self rgbToHSV:rgb hsv:hsv];
            
            if ((hsv[0] > minBlue) && (hsv[0] < maxBlue)) {
                alpha = 1;
            } else if ((hsv[0] > minYellow) && (hsv[0] < maxYellow)) {
                if ((hsv[1] > satureLimitLow) && (hsv[1] < satureLimitHigh))
                    alpha = [self checkBrightnessRangeX:x withY:y];
                else
                    alpha = 0;
                
                yellowAlphaData[y * width + x] = alpha;
            } else
                alpha = 0;
            
            if (alpha) {
                rgbaValues[0] = 255;
                rgbaValues[1] = orgValues[0];
                rgbaValues[2] = orgValues[1];
                rgbaValues[3] = orgValues[2];
            } else {
                rgbaValues[0] = 255;
                
                if (f_landscapeImage) {
                    rgbaValues[1] = grayValues[y * (width+diffPixelCount) + x];
                    rgbaValues[2] = grayValues[y * (width+diffPixelCount) + x];
                    rgbaValues[3] = grayValues[y * (width+diffPixelCount) + x];
                } else {
                    rgbaValues[1] = grayValues[y * width + x];
                    rgbaValues[2] = grayValues[y * width + x];
                    rgbaValues[3] = grayValues[y * width + x];
                }
            }
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
    UIImage *image = [UIImage imageWithCGImage:newCGImage];
    CGImageRelease(newCGImage);
    CGContextRelease(context);
    
    return image;
}

- (void) removingNoise:(CGPoint)pos {
    CGPoint realPos;
    int x, y;
    if (UIInterfaceOrientationIsLandscape(from)) {
        realPos = CGPointMake(pos.x - (ResultImageView.frame.size.width - ResultImageView.frame.size.height) / 2, pos.y);
        x = (int)((realPos.x / ResultImageView.frame.size.height) * width);
        y = (int)((realPos.y / ResultImageView.frame.size.height) * height);
    }
    else {
        realPos = CGPointMake(pos.x,
                              pos.y - (ResultImageView.frame.size.height - ResultImageView.frame.size.width) / 2);
        x = (int)((realPos.x / ResultImageView.frame.size.width) * width);
        y = (int)((realPos.y / ResultImageView.frame.size.width) * height);
    }
    
    
    uint8_t* grayValues = (uint8_t*)CFDataGetBytePtr(grayData);
    uint8_t* rgbaValues;
    int i,j;
    
    for (j = y - drawingThick; j <= y + drawingThick; j++) {
        if ((j < 0) || (j >= height))
            continue;
        for (i = x - drawingThick; i <= x + drawingThick; i++) {
            if ((i < 0) || (i >= width))
                continue;

            if (yellowAlphaData[j * width + i]) {
                rgbaValues = (uint8_t*)&drawingData[j * width + i];
                
                rgbaValues[0] = 255;
                if (f_landscapeImage) {
                    rgbaValues[1] = grayValues[j * (width+diffPixelCount) + i];
                    rgbaValues[2] = grayValues[j * (width+diffPixelCount) + i];
                    rgbaValues[3] = grayValues[j * (width+diffPixelCount) + i];
                } else {
                    rgbaValues[1] = grayValues[j * width + i];
                    rgbaValues[2] = grayValues[j * width + i];
                    rgbaValues[3] = grayValues[j * width + i];
                }
                yellowAlphaData[j * width + i] = 0;
            }
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
    UIImage *image = [UIImage imageWithCGImage:newCGImage];
    CGImageRelease(newCGImage);
    CGContextRelease(context);
    
    //Get final result image
    ResultImageView.image = image;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    
    // Dispose of any resources that can be recreated.
}

- (void) freeMemory {
    CFRelease(orgRawData);
    CFRelease(waterMarkData);
    CFRelease(grayData);
    
    if (drawingData != nil)
        free (drawingData);
    drawingData = nil;
    
    if (brightnessData != nil)
        free(brightnessData);
    brightnessData = nil;
    
    if (yellowAlphaData != nil)
        free (yellowAlphaData);
    yellowAlphaData = nil;
#if 0
    if (pixelCalcData != nil)
        free (pixelCalcData);
    pixelCalcData = nil;
    
    if (pixelValueData != nil)
        free (pixelValueData);
    pixelValueData = nil;
    
    if (pixelAlphaData != nil)
        free (pixelAlphaData);
    pixelAlphaData = nil;
    
    if (pixelAlphaTempData != nil)
        free (pixelAlphaTempData);
    pixelAlphaTempData = nil;
#endif
}

-(void)viewDidUnload {
    [super viewDidUnload];
    
    [self freeMemory];
}

- (void) blueAngleFirstChanged:(ColorRangePickerSlider *)slider
{
	blueAngVal1 = 360 - slider.value;
    [self updateResultView];
}

- (void) blueAngleSecondChanged:(ColorRangePickerSlider *)slider
{
	blueAngVal2 = 360 - slider.value;
    [self updateResultView];
}

- (void) yellowAngleFirstChanged:(ColorRangePickerSlider *)slider
{
	yellowAngVal1 = 360 - slider.value;
    [self updateResultView];
}

- (void) yellowAngleSecondChanged:(ColorRangePickerSlider *)slider
{
	yellowAngVal2 = 360 - slider.value;
    [self updateResultView];
}

- (void) brightChanged:(ColorRangePickerSlider *)slider
{
	brightLimitVal = 360 - slider.value;
    [self updateResultView];
}

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    from = [UIDevice currentDevice].orientation;
    
    [self updateSliderRegion];

    [UIView animateWithDuration:0.5f
                          delay:0
                        options:UIViewAnimationCurveLinear
                     animations:^{
                         toolBar.alpha = 1.0f;
                     }
                     completion:^(BOOL finished) {
                         f_showToolBar = true;
                         [self performSelector:@selector(hideToolBar) withObject:nil afterDelay:0.0f];
                         f_animating = true;
                     }];
}
- (void) viewWillDisappear:(BOOL)animated
{
    if ([self.navigationController.viewControllers indexOfObject:self]==NSNotFound)
        [self freeMemory];
    
    [super viewWillDisappear:animated];
}

-(IBAction)onSave:(id)sender {
    UIImageWriteToSavedPhotosAlbum(ResultImageView.image, nil, nil, nil);
    UIAlertView * svOkAlert = [[UIAlertView alloc]initWithTitle:Nil message:@"Saved successfully" delegate:Nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
    [svOkAlert show];
}

- (IBAction)onSend:(id)sender {
    UIImageWriteToSavedPhotosAlbum(ResultImageView.image, nil, nil, nil);
    MFMailComposeViewController *controller = [[MFMailComposeViewController alloc] init];
    controller.mailComposeDelegate = self;
    if ([MFMailComposeViewController canSendMail])
    {
        NSMutableString *body = [NSMutableString string];
        [controller setSubject:@"Sending Image"];
        
        NSData *myData = UIImageJPEGRepresentation(ResultImageView.image, 1.0);
        
        [controller addAttachmentData:myData mimeType:@"image/png" fileName:@"coolImage"];
        controller.mailComposeDelegate = self;
        
        [self presentModalViewController:controller animated:YES];
    }
}


- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error
{
    
    [controller dismissViewControllerAnimated:YES completion:^{
        switch (result) {
            case MFMailComposeResultCancelled:
            {
//                UIAlertView *alert = [[UIAlertView alloc]initWithTitle:Nil message:@"Mail has been Cancelled" delegate:Nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
//                [alert show];
                break;
            }
            case MFMailComposeResultSaved:
            {
                UIAlertView *alert = [[UIAlertView alloc]initWithTitle:Nil message:@"Mail has been Saved" delegate:Nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
                [alert show];
                break;
            }
            case MFMailComposeResultSent:
            {
                UIAlertView *alert = [[UIAlertView alloc]initWithTitle:Nil message:@"Mail has been Sent" delegate:Nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
                [alert show];            break;
            }
            case MFMailComposeResultFailed:
            {
                UIAlertView *alert = [[UIAlertView alloc]initWithTitle:Nil message:@"Mail has been Sent Failed" delegate:Nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
                [alert show];
                break;
            }
            default:
                break;
        }
    }];
}

- (void)_handleTouch:(UITapGestureRecognizer*)recognizer {
    if (f_animating)
        return;
    
    f_animating = true;
    if (f_showToolBar)
        [self performSelector:@selector(hideToolBar) withObject:nil afterDelay:0.3f];
    else
        [self performSelector:@selector(showToolBar) withObject:nil afterDelay:0.3f];
}

- (void)_handlePan:(UIPanGestureRecognizer*)recognizer {
    curPos = [recognizer locationInView:ResultImageView];
    [self removingNoise:curPos];
}

-(BOOL)shouldAutorotate {
    return YES;
}

-(NSUInteger)supportedInterfaceOrientations{
    return UIInterfaceOrientationMaskAll;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    
    if (UIInterfaceOrientationIsLandscape(from) == UIInterfaceOrientationIsLandscape(toInterfaceOrientation))
        return;
    
    if (f_showToolBar == f_animating)
        toolBar.alpha = 0.0f;
}
- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    from = [UIDevice currentDevice].orientation;
    
    if (UIInterfaceOrientationIsLandscape(from) == UIInterfaceOrientationIsLandscape(fromInterfaceOrientation))
        return;
    
    [self updateSliderRegion];

    if (f_showToolBar == f_animating) {
        [toolBar setCenter:CGPointMake(toolBar.center.x, toolBar.center.y + toolBar.frame.size.height - 50)];
        [UIView animateWithDuration:0.5f
                              delay:0
                            options:UIViewAnimationCurveLinear
                         animations:^{
                             toolBar.alpha = 0.5f;
                         }
                         completion:^(BOOL finished) {
                         }];
    }
}

- (void) updateSliderRegion {
    CGSize sliderSize = sliderRegion.bounds.size;
    int sliderWidth = (sliderSize.width - 40) / 2;
    int sliderHeight = 40;
    int gapX1 = 10;
    int gapX2 = 20;
    int gapY1 = (sliderSize.height - sliderHeight * 2) / 3;
    int gapY2 = (sliderSize.height - sliderHeight * 3) / 4;
    
    [blueAng1 setFrame: CGRectMake(gapX1, gapY1, sliderWidth, sliderHeight)];
    [blueAng2 setFrame:CGRectMake(gapX1, gapY1*2+sliderHeight, sliderWidth, sliderHeight)];
    [yellowAng1 setFrame:CGRectMake(gapX1+gapX2+sliderWidth, gapY2, sliderWidth, sliderHeight)];
    [yellowAng2 setFrame:CGRectMake(gapX1+gapX2+sliderWidth, gapY2*2+sliderHeight,
                                    sliderWidth, sliderHeight)];
    [brightBar setFrame:CGRectMake(gapX1+gapX2+sliderWidth, gapY2*3+sliderHeight*2,
                                   sliderWidth, sliderHeight)];
    
    blueAng1.value = 1.0 - blueAngVal1 / 360.0f;
    blueAng2.value = 1.0 - blueAngVal2 / 360.0f;
    yellowAng1.value = 1.0 - yellowAngVal1 / 360.0f;
    yellowAng2.value = 1.0 - yellowAngVal2 / 360.0f;
    brightBar.value = 1.0 - brightLimitVal / 360.0f;
}

#if 0
- (void) medianFilter {
    uint8_t* rgbaValues;
    uint8_t* medianValue;
    
    for (int y = 0; y < height; y++)
    {
        for (int x = 0; x < width; x++)
        {
            rgbaValues = (uint8_t*)&drawingData[y * width + x];
            medianValue = [self _calcMedianValue:x withY:y];
            
            rgbaValues[0] = medianValue[3];
            rgbaValues[1] = medianValue[0];
            rgbaValues[2] = medianValue[1];
            rgbaValues[3] = medianValue[2];
        }
    }
}

- (uint8_t*) _calcMedianValue:(int)x withY:(int)y {
    float rgb[3], hsv[3];
    uint32_t* data = (uint32_t*)CFDataGetBytePtr(orgRawData);
    int *indexArray;
    float *brightArray;
    float zMin, zMax, zMed, zXY;
    int indexMed;
    float A1, A2, B1, B2;
    int k;
    
    uint8_t* orgValues = (uint8_t*)&data[y * width + x];
    rgb[0] = orgValues[0] / 255.0f;
    rgb[1] = orgValues[1] / 255.0f;
    rgb[2] = orgValues[2] / 255.0f;
    [self rgbToHSV:rgb hsv:hsv];
    zXY = hsv[2] * 255.0f;
    
    for (int windowSize = 1; windowSize < 4; windowSize++) {
        int arrayCount = (2*windowSize+1) * (2*windowSize+1);
        
        indexArray = malloc(sizeof(int) * arrayCount);
        brightArray = malloc(sizeof(float) * arrayCount);
        memset(indexArray, 0, sizeof(int) * arrayCount);
        memset(brightArray, 0, sizeof(float) * arrayCount);
        
        for (int j = 0; j <= windowSize * 2; j++) {
            if ((j + y - windowSize) < 0)
                continue;
            if ((j + y - windowSize) >= height)
                continue;
            
            for (int i = 0; i <= windowSize * 2; i++) {
                if ((i + x - windowSize) < 0)
                    continue;
                if ((i + x - windowSize) > width)
                    continue;
                
                orgValues = (uint8_t*)&data[(j + y - windowSize) * width + i + x - windowSize];
                rgb[0] = orgValues[0] / 255.0f;
                rgb[1] = orgValues[1] / 255.0f;
                rgb[2] = orgValues[2] / 255.0f;
                [self rgbToHSV:rgb hsv:hsv];
                
                indexArray[j * (windowSize * 2 + 1) + i] = (j + y - windowSize) * width + i + x - windowSize;
                brightArray[j * (windowSize * 2 + 1) + i] = hsv[2] * 255.0f;
            }
        }
        
        for (int i = 0; i < arrayCount-1; i++) {
            for (int j = i+1; j < arrayCount; j++) {
                if (brightArray[i] < brightArray[j]) {
                    float tempBright = brightArray[j];
                    brightArray[j] = brightArray[i];
                    brightArray[i] = tempBright;
                    
                    int tempIndex = indexArray[j];
                    indexArray[j] = indexArray[i];
                    indexArray[i] = tempIndex;
                }
            }
        }
        
        zMin = 255;
        zMax = 0;
        for (k = 0; k < arrayCount-1; k++) {
            if (brightArray[k] == 0)
                break;
            
            if (brightArray[k] > zMax)
                zMax = brightArray[k];
            
            if (brightArray[k] < zMin)
                zMin = brightArray[k];
        }
        
        zMed = brightArray[(k / 2)];
        indexMed = indexArray[(k / 2)];

        free(brightArray);
        free(indexArray);
        
        A1 = zMed - zMin;
        A2 = zMed - zMax;
        if ((A1 > 0) && (A2 < 0)) {
            B1 = zXY - zMin;
            B2 = zXY - zMax;
            if ((B1 > 0) && (B2 < 0))
                return (uint8_t*)&data[y * width + x];
            
            return (uint8_t*)&data[indexMed];
        }
    }

    return (uint8_t*)&data[y * width + x];
}

- (void) calcPixelValue {
    float *pixelValues;
    uint8_t *rgbaValues;
    int x, y;
    
    for (y = 0; y < height; y++)
    {
        for (x = 0; x < width; x++)
        {
            rgbaValues = (uint8_t*)&drawingData[y * width + x];
            pixelValues = &pixelCalcData[y * width + x];
            
            *pixelValues = rgbaValues[1] * 2 + rgbaValues[2] * 3 + rgbaValues[3] * 4;
        }
    }
}

- (void) apply4Mask {
    int x, y;
    float pixelValue0, pixelValue90, pixelValue135, pixelValue45, pixelValueMax;
    
    for (y = 0; y < height; y++)
    {
        if ((y == 0) || (y == height-1)) {
            pixelValue90 = 0;
            pixelValue135 = 0;
            pixelValue45 = 0;
            continue;
        }
        
        for (x = 0; x < width; x++)
        {
            if ((x == 0) || (x == width-1)) {
                pixelValue0 = 0;
                pixelValue135 = 0;
                pixelValue45 = 0;
            }
            else {
                pixelValue0 = abs(pixelCalcData[y * width + (x-1)] - pixelCalcData[y * width + (x+1)]);
                pixelValue135 = abs(pixelCalcData[(y-1) * width + (x-1)] - pixelCalcData[(y+1) * width + (x+1)]);
                pixelValue45 = abs(pixelCalcData[(y+1) * width + (x-1)] - pixelCalcData[(y-1) * width + (x+1)]);
            }
            pixelValue90 = abs(pixelCalcData[(y-1) * width + x] - pixelCalcData[(y+1) * width + x]);

            pixelValueMax = pixelValue0;
            if (pixelValueMax < pixelValue90)
                pixelValueMax = pixelValue90;
            if (pixelValueMax < pixelValue135)
                pixelValueMax = pixelValue135;
            if (pixelValueMax < pixelValue45)
                pixelValueMax = pixelValue45;
            
            pixelValueData[y * width + x] = pixelValueMax;
        }
    }
}

- (void) limitThreshold {
    int x, y;
    Float64 totalSum = 0;
    float t = 0;
    
    for (y = 0; y < height; y++)
    {
        for (int x = 0; x < width; x++)
            totalSum += pixelValueData[y * width + x];
    }
    
    t = totalSum / (width * height) * 1.2;
    
    for (y = 0; y < height; y++)
    {
        for (x = 0; x < width; x++)
        {
            if (pixelValueData[y * width + x] >= t)
                pixelAlphaData[y * width + x] = 1;
            else
                pixelAlphaData[y * width + x] = 0;
        }
    }
    memcpy(pixelAlphaTempData, pixelAlphaData, width * height * sizeof(int));
}

- (void) limitIntensity {
    int x, y, i, j;
    int size = (intensitySegment*2+1) * (intensitySegment*2+1);
    int temp = 0;
    uint8_t *rgbaValues;
    float rgb[3], hsv[3], totalHue, count;
    int index, alpha;
    
    for (y = intensitySegment; y < height - intensitySegment; y++)
    {
        for (x = intensitySegment; x < width - intensitySegment; x++) {
            if (pixelAlphaData[y * width + x] != 1)
                continue;
            
            //Calc Hue total value in segment
            totalHue = 0;
            count = 0;
            
            for (j = 0; j <= intensitySegment * 2; j++) {
                for (i = 0; i <= intensitySegment * 2; i++) {
                    index = (j+y-intensitySegment) * width + (i+x-intensitySegment);
                    if (pixelAlphaTempData[index] != 1)
                        continue;
                    
                    rgbaValues = (uint8_t*)&drawingData[index];
                    
                    rgb[0] = rgbaValues[1] / 255.0f;
                    rgb[1] = rgbaValues[2] / 255.0f;
                    rgb[2] = rgbaValues[3] / 255.0f;
                    [self rgbToHSV:rgb hsv:hsv];
                    
                    alpha = (hsv[1] <= satureLimitLow || hsv[1] >= satureLimitHigh) ? 0 : 1;
                    if (!alpha)
                        continue;
                    
                    totalHue += hsv[0];
                    count++;
                }
            }
            
            if ((totalHue < yellowLimitLow * size) ||
                (count < size * 0.6))
                pixelAlphaData[y * width + x] = 0;
            else {
                for (j = 0; j <= intensitySegment * 2; j++) {
                    for (i = 0; i <= intensitySegment * 2; i++) {
                        index = (j+y-intensitySegment) * width + (i+x-intensitySegment);
                        pixelAlphaData[index] = 1;
                    }
                }
            }
        }
    }
    
    memcpy(pixelAlphaTempData, pixelAlphaData, width * height * sizeof(int));
}

- (int) _calcConnectivity:(int)x withY:(int)y {
    int P[8] = {(y-1)*width+x, (y-1)*width+x+1, y*width+x+1, (y+1)*width+x+1,
                (y+1)*width+x, (y+1)*width+x-1, y*width+x-1, (y-1)*width+x-1};
    int C = 0;
    int i = 0;
    
    for (i = 0; i < 8; i++) {
        if (i == 7) {
            if ((pixelAlphaTempData[P[i]] == 0) &&
                (pixelAlphaTempData[P[0]] == 1))
                C++;
        } else {
            if ((pixelAlphaTempData[P[i]] == 0) &&
                (pixelAlphaTempData[P[i+1]] == 1))
                C++;
        }
    }
    
    return C;
}

- (int) _calcNeighborCount:(int)x withY:(int)y {
    int count = 0;
    
    for (int i = y-1; i <= y+1; i++) {
        for (int j = x-1; j <= x+1; j++) {
            if ((i == y) && (j == x))
                continue;

            if (pixelAlphaTempData[i * width + j])
                count++;
        }
    }
    
    return count;
}

- (int) _smoothing:(int)x withY:(int)y {
    int neighCount = [self _calcNeighborCount:x withY:y];
    int connectivity = [self _calcConnectivity:x withY:y];
    
    if ((neighCount < 3) && (connectivity < 2))
        return 0;
    
    return 1;
}

- (BOOL) _match:(int)x withY:(int)y withP:(int*)P withV:(int*)V {
    BOOL result = true;
    
    for (int i = 0; i < 25; i++) {
        if (V[i] == 2)
            continue;
        
        switch (V[i]) {
            case 0:
                if (pixelAlphaTempData[P[i]] != 0)
                    result = false;
                break;
            case 1:
                if (pixelAlphaTempData[P[i]] != 1)
                    result = false;
                break;
            default:
                break;
        }
        
        if (!result)
            break;
    }
    
    return result;
}

- (BOOL) _matchMask:(int)x withY:(int)y withK:(int)k {
    int P[25] = {(y-2)*width+x-2, (y-2)*width+x-1, (y-2)*width+x, (y-2)*width+x+1, (y-2)*width+x+2,
                 (y-1)*width+x-2, (y-1)*width+x-1, (y-1)*width+x, (y-1)*width+x+1, (y-1)*width+x+2,
                 y*width+x-2, y*width+x-1, y*width+x, y*width+x+1, y*width+x+2,
                 (y+1)*width+x-2, (y+1)*width+x-1, (y+1)*width+x, (y+1)*width+x+1, (y+1)*width+x+2,
                 (y+2)*width+x-2, (y+2)*width+x-1, (y+2)*width+x, (y+2)*width+x+1, (y+2)*width+x+2};
    
    int V1[25] = {1, 1, 0, 1, 1,
                  1, 1, 0, 1, 1,
                  1, 1, 1, 1, 1,
                  1, 1, 1, 1, 1,
                  2, 1, 1, 1, 2};
    
    int V2[25] = {2, 1, 1, 1, 2,
                  1, 1, 1, 1, 1,
                  1, 1, 1, 1, 1,
                  1, 1, 0, 1, 1,
                  1, 1, 0, 1, 1};
    
    //D1
    if ([self _match:x withY:y withP:P withV:V1])
        return true;
    
    //D2
    if (k >= 2) {
        V1[1] = 0;
        if ([self _match:x withY:y withP:P withV:V1])
            return true;
    }
    
    //D3
    if (k >= 3) {
        V1[1] = 1;
        V1[3] = 0;
        if ([self _match:x withY:y withP:P withV:V1])
            return true;
    }
    
    //D4
    if (k >= 4) {
        V1[1] = 0;
        V1[3] = 1;
        V1[6] = 0;
        if ([self _match:x withY:y withP:P withV:V1])
            return true;
    }
    
    //D5
    if (k >= 5) {
        V1[1] = 1;
        V1[3] = 0;
        V1[6] = 1;
        V1[8] = 0;
        if ([self _match:x withY:y withP:P withV:V1])
            return true;
    }
    
    //U1
    if ([self _match:x withY:y withP:P withV:V2])
        return true;
    
    //U2
    if (k >= 2) {
        V2[21] = 0;
        if ([self _match:x withY:y withP:P withV:V2])
            return true;
    }
    
    //U3
    if (k >= 3) {
        V2[21] = 1;
        V2[23] = 0;
        if ([self _match:x withY:y withP:P withV:V2])
            return true;
    }
    
    //U4
    if (k >= 4) {
        V2[16] = 0;
        V2[21] = 0;
        V2[23] = 1;
        if ([self _match:x withY:y withP:P withV:V2])
            return true;
    }
    
    //U5
    if (k >= 5) {
        V2[16] = 1;
        V2[18] = 0;
        V2[21] = 1;
        V2[23] = 0;
        if ([self _match:x withY:y withP:P withV:V2])
            return true;
    }
    
    return false;
}

- (void) thining {
    BOOL f_change;
    int x, y, k;
    int p1, p2;
    int neighCount, connectivity;
    int c,e,ne,n,nw,w,sw,s,se;
    
    //Preprocess: smoothing
    for (y = 1; y < height - 1; y++)
    {
        for (x = 1; x < width - 1; x++)
        {
            if (pixelAlphaData[y * width + x])
                pixelAlphaData[y * width + x] = [self _smoothing:x withY:y];
        }
    }
    memcpy(pixelAlphaTempData, pixelAlphaData, width * height * sizeof(int));
    
    //Preprocess: Acute Angle Emphasis
    for (k = 5; k >= 1; k -= 2) {
        f_change = false;
        
        for (y = 2; y < height - 2; y++) {
            for (x = 2; x < width - 2; x++) {
                if (pixelAlphaData[y * width + x] != 1)
                    continue;
                
                if ([self _matchMask:x withY:y withK:k]) {
                    f_change = true;
                    pixelAlphaData[y * width + x] = 0;
                }
            }
        }
        
        if (f_change == false)
            break;
        else
            memcpy(pixelAlphaTempData, pixelAlphaData, width * height * sizeof(int));
    }
    
    //Zhang-Suen Thining
    while (true) {
        f_change = false;
        
        for (y = 1; y < height - 1; y++) {
            for (x = 1; x < width - 1; x++) {
                if (pixelAlphaData[y * width + x] != 1)
                    continue;
                
                neighCount = [self _calcNeighborCount:x withY:y];
                connectivity = [self _calcConnectivity:x withY:y];
                if ((neighCount >= 2) && (neighCount <= 6) &&
                    (connectivity == 1)) {
                    p1 = pixelAlphaTempData[y*width+x+1] * pixelAlphaTempData[(y-1)*width+x] *
                        pixelAlphaTempData[y*width+x-1];
                    
                    p2 = pixelAlphaTempData[(y-1)*width+x] * pixelAlphaTempData[(y+1)*width+x] *
                        pixelAlphaTempData[y*width+x-1];
                    
                    if ((p1 == 0) && (p2 == 0)) {
                        f_change = true;
                        pixelAlphaData[y * width + x] = 0;
                    }
                }
            }
        }
        
        if (f_change == false)
            break;
        else
            memcpy(pixelAlphaTempData, pixelAlphaData, width * height * sizeof(int));

        f_change = false;
        
        for (y = 1; y < height - 1; y++) {
            for (x = 1; x < width - 1; x++) {
                if (pixelAlphaData[y * width + x] != 1)
                    continue;
                
                neighCount = [self _calcNeighborCount:x withY:y];
                connectivity = [self _calcConnectivity:x withY:y];
                if ((neighCount >= 2) && (neighCount <= 6) &&
                    (connectivity == 1)) {
                    p1 = pixelAlphaTempData[(y-1)*width+x] * pixelAlphaTempData[y*width+x+1] *
                    pixelAlphaTempData[(y+1)*width+x];
                    
                    p2 = pixelAlphaTempData[y*width+x+1] * pixelAlphaTempData[(y+1)*width+x] *
                    pixelAlphaTempData[y*width+x-1];
                    
                    if ((p1 == 0) && (p2 == 0)) {
                        f_change = true;
                        pixelAlphaData[y * width + x] = 0;
                    }
                }
            }
        }
        
        if (f_change == false)
            break;
        else
            memcpy(pixelAlphaTempData, pixelAlphaData, width * height * sizeof(int));
    }
    
    //Holt's staircase removal
    for (k = 0; k < 2; k++) {
        for (y = 1; y < height - 1; y++) {
            for (x = 1; x < width - 1; x++) {
                c = pixelAlphaData[y * width + x];
                if (c != 1)
                    continue;
                
                e = pixelAlphaTempData[y*width+x+1];
                ne = pixelAlphaTempData[(y-1)*width+x+1];
                n = pixelAlphaTempData[(y-1)*width+x];
                nw = pixelAlphaTempData[(y-1)*width+x-1];
                w = pixelAlphaTempData[y*width+x-1];
                sw = pixelAlphaTempData[(y+1)*width+x-1];
                s = pixelAlphaTempData[(y+1)*width+x];
                se = pixelAlphaTempData[(y+1)*width+x+1];
                
                if (k == 0) {
                    if (!(c && !(n &&
                         ((e && !ne && !sw && (!w || !s)) ||
                          (w && !nw && !se && (!e || !s))))))
                    {
                        pixelAlphaData[y * width + x] = 0;
                    }
                } else {
                    if (!(c && !(s &&
                         ((e && !se && !nw && (!w || !n)) ||
                          (w && !sw && !ne && (!e || !n))))))
                    {
                        pixelAlphaData[y * width + x] = 0;
                    }
                }
            }
        }
    }
    memcpy(pixelAlphaTempData, pixelAlphaData, width * height * sizeof(int));
}

- (void) removeSinglePixel {
    int x, y;
    int neighCount;
    
    for (y = 1; y < height - 1; y++) {
        for (x = 1; x < width - 1; x++) {
            if (pixelAlphaData[y * width + x] != 1)
                continue;
            
            neighCount = [self _calcNeighborCount:x withY:y];
            if (!neighCount)
                pixelAlphaData[y * width + x] = 0;
        }
    }
    memcpy(pixelAlphaTempData, pixelAlphaData, width * height * sizeof(int));
}

- (void) filling {
    int x, y, k;
    int firstPos = -1, endPos = -1;
    int prevFirstPos = -1, prevEndPos = -1;
    int *tempData = malloc(width * height * sizeof(int));
    
    // degree 0
    for (y = 0; y < height; y++) {
        firstPos = -1;
        endPos = -1;
        
        for (x = 0; x < width; x++) {
            if (pixelAlphaTempData[y * width + x] != 1)
                continue;
            
            if (firstPos < 0)
                firstPos = x;
            else if (endPos < 0) {
                endPos = x;
                for (k = firstPos; k <= endPos; k++)
                    pixelAlphaData[y * width + k] = 1;
                
                prevFirstPos = firstPos;
                prevEndPos = endPos;
                
                firstPos = -1;
                endPos = -1;
            }
        }
        
        if ((firstPos >= 0) && (endPos < 0))
            pixelAlphaData[y * width + firstPos] = 0;
        if ((firstPos < 0) && (endPos < 0)) {
            for (k = prevFirstPos; k <= prevEndPos; k++)
                pixelAlphaData[y * width + k] = 1;
        }
    }
    
    // degree 90
    memset(tempData, 0, width * height * sizeof(int));
    for (x = 0; x < width; x++) {
        firstPos = -1;
        endPos = -1;
        
        for (y = 0; y < height; y++) {
            if (pixelAlphaTempData[y * width + x] != 1)
                continue;
            
            if (firstPos < 0)
                firstPos = y;
            else if (endPos < 0) {
                endPos = y;
                for (k = firstPos; k <= endPos; k++) {
                    if (pixelAlphaData[k * width + x])
                        tempData[k * width + x] = 1;
                }
                
                prevFirstPos = firstPos;
                prevEndPos = endPos;
                
                firstPos = -1;
                endPos = -1;
            }
        }
        
        if ((firstPos >= 0) && (endPos < 0))
            pixelAlphaData[firstPos * width + x] = 0;
        if ((firstPos < 0) && (endPos < 0)) {
            for (k = prevFirstPos; k <= prevEndPos; k++)
                pixelAlphaData[k * width + x] = 1;
        }
    }
    memcpy(pixelAlphaData, tempData, width * height * sizeof(int));
    free(tempData);
    
    memcpy(pixelAlphaTempData, pixelAlphaData, width * height * sizeof(int));
}

- (void) finalizing {
    int x, y, i, j;
    uint8_t *rgbaValues;
    float count;
    int index, temp;
    int size = (fillSegment * 2 + 1) * (fillSegment * 2 + 1);
    
    for (y = fillSegment; y < height - fillSegment; y++)
    {
        for (x = fillSegment; x < width - fillSegment; x++) {
            if (pixelAlphaData[y * width + x] != 1)
                continue;
            
            //Calc total count
            count = 0;
            
            for (j = 0; j <= fillSegment * 2; j++) {
                for (i = 0; i <= fillSegment * 2; i++) {
                    index = (j+y-fillSegment) * width + (i+x-fillSegment);
                    if (pixelAlphaTempData[index] != 1)
                        continue;
                    count++;
                }
            }
            
            if (count < size * 0.8)
                temp = 0;
            else
                temp = 1;

            for (j = 0; j <= fillSegment * 2; j++) {
                for (i = 0; i <= fillSegment * 2; i++) {
                    index = (j+y-fillSegment) * width + (i+x-fillSegment);
                    pixelAlphaData[index] = temp;
                }
            }

        }
    }
    
    memcpy(pixelAlphaTempData, pixelAlphaData, width * height * sizeof(int));
}

- (void) removeNoise {
    int x, y, j, i;
    int maxVal, minVal;
    int index;
    
    for (y = removeSegment; y < height - removeSegment; y++)
    {
        for (x = removeSegment; x < width - removeSegment; x++) {
            if (pixelAlphaData[y * width + x] != 1)
                continue;
            
            //Calc max diff
            maxVal = -1;
            minVal = pixelCalcData[y * width + x];

            for (j = 0; j <= removeSegment * 2; j++) {
                for (i = 0; i <= removeSegment * 2; i++) {
                    index = (j+y-removeSegment) * width + (i+x-removeSegment);
                    if (pixelAlphaTempData[index] != 1)
                        continue;
                    
                    if (maxVal < pixelCalcData[index])
                        maxVal = pixelCalcData[index];
                    if (minVal > pixelCalcData[index])
                        minVal = pixelCalcData[index];
                }
            }
            
            if ((maxVal - minVal) < 100)
                pixelAlphaData[y * width + x] = 0;
            if (minVal < 100)
                pixelAlphaData[y * width + x] = 0;
//            if (maxVal > 1000)
//                pixelAlphaData[y * width + x] = 0;
        }
    }
    
    memcpy(pixelAlphaTempData, pixelAlphaData, width * height * sizeof(int));
}

- (void) showImage {
    int x,y;
    uint8_t* rgbaValues;
    uint8_t* tempValues;
    uint32_t* tempData = malloc(width * height * sizeof(uint32_t));
    int alpha;
    float rgb[3], hsv[3];
    
    float realAngVal1 = yellowLimitLow + (yellowAngVal1 / 360.0f) * (yellowLimitHigh - yellowLimitLow);
    float realAngVal2 = yellowLimitLow + (yellowAngVal2 / 360.0f) * (yellowLimitHigh - yellowLimitLow);
    
    for (y = 0; y < height; y++)
    {
        for (x = 0; x < width; x++)
        {
            rgbaValues = (uint8_t*)&drawingData[y * width + x];
            tempValues = (uint8_t*)&tempData[y * width + x];
            
            alpha = pixelAlphaData[y * width + x];
            
            rgb[0] = rgbaValues[1] / 255.0f;
            rgb[1] = rgbaValues[2] / 255.0f;
            rgb[2] = rgbaValues[3] / 255.0f;
            [self rgbToHSV:rgb hsv:hsv];
            
            if (alpha) {
                alpha = (hsv[0] <= MIN(realAngVal1, realAngVal2) || hsv[0] >= MAX(realAngVal1, realAngVal2)) ? 0 : 1;
                if (alpha == 1) {
                    alpha = (hsv[1] <= satureLimitLow || hsv[1] >= satureLimitHigh) ? 0 : 1;
                    if (alpha == 1)
                        alpha = [self checkBrightnessRangeX:x withY:y];
                }
            }
            
            tempValues[0] = 255 * alpha;
            tempValues[1] = rgbaValues[1] * alpha;
            tempValues[2] = rgbaValues[2] * alpha;
            tempValues[3] = rgbaValues[3] * alpha;
            
        }
    }
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    NSUInteger bytesPerPixel = 4;
    NSUInteger bytesPerRow = bytesPerPixel * width;
    NSUInteger bitsPerComponent = 8;
    CGContextRef context = CGBitmapContextCreate(tempData, width, height,
                                                 bitsPerComponent, bytesPerRow, colorSpace,
                                                 kCGImageAlphaPremultipliedFirst);
    CGColorSpaceRelease(colorSpace);

    CGImageRef newCGImage = CGBitmapContextCreateImage(context);
    yellowHighlighted = [CIImage imageWithCGImage:newCGImage];
    CGImageRelease(newCGImage);
    CGContextRelease(context);

    CIImage *yellowResult = [self mergeWithBackground:yellowHighlighted background:backImage];
    
    //Get final result image
    CIImage *blueResult = BlueHighligtedImageView.image.CIImage;
    finalResultImage = [self mergeWithBackground:yellowHighlighted background:blueResult];
    
    YellowHighligtedImageView.image = [UIImage imageWithCIImage:yellowResult];
    
    free(tempData);
}

-(IBAction)onColor:(id)sender {
    mode = COLOR_MODE;
    
    [activity startAnimating];
    [self.view setAlpha:0.5f];
    [self.view setUserInteractionEnabled:false];
    
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 0.5 * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        @autoreleasepool {
            [self calcBrightness];
            [self updateBlueResultView];
            [self updateYellowResultView];
        }
        
        [activity stopAnimating];
        [self.view setAlpha:1.0f];
        [self.view setUserInteractionEnabled:true];
    });
}

-(IBAction)onColorRegion:(id)sender {
    mode = REGION_MODE;
    
    [activity startAnimating];
    [self.view setAlpha:0.5f];
    [self.view setUserInteractionEnabled:false];
    
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 0.5 * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        @autoreleasepool {
            //Detect color edge
            [self medianFilter];
            [self calcPixelValue];
            [self apply4Mask];
            [self limitThreshold];
            
            [self removeNoise];
            //Thining
//            [self thining];
            
            //Removing single pixel
//            [self removeSinglePixel];
            
            //Filter intensity
//            [self limitIntensity];
            
            //Filling
//            [self filling];
            
            //Finalizing
//            [self finalizing];
            
            //Show result image
            [self showImage];
        }
        
        [activity stopAnimating];
        [self.view setAlpha:1.0f];
        [self.view setUserInteractionEnabled:true];
    });
}

-(IBAction)onColorLine:(id)sender {
    mode = LINE_MODE;
    
    [activity startAnimating];
    [self.view setAlpha:0.5f];
    [self.view setUserInteractionEnabled:false];
    
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 0.5 * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        @autoreleasepool {
            //Detect color edge
            [self medianFilter];
            [self calcPixelValue];
            [self apply4Mask];
            [self limitThreshold];
            
            //Thining
//            [self thining];
            
            //Removing single pixel
//            [self removeSinglePixel];
            
            //Filling
//            [self filling];
            
            //Finalizing
//            [self finalizing];
            
            //Show result image
            [self showImage];
        }
        
        [activity stopAnimating];
        [self.view setAlpha:1.0f];
        [self.view setUserInteractionEnabled:true];
    });
}
#endif
@end
