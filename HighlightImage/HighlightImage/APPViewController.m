//
//  APPViewController.m
//  HighlightImage
//
//  Created by JiangJian on 19/4/14.
//  Copyright (c) 2014 hanayonghe. All rights reserved.
//

#import "APPViewController.h"
#import "ImageBrowserViewController.h"

@interface APPViewController () {
    UIImage *capturedImage;
    
    UIButton *_coverView;
}

@end

@implementation APPViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    count = 0;
    
    /**chg by viziner jym **/
    _coverView = [[UIButton alloc]initWithFrame:[UIScreen mainScreen].bounds ];
    [_coverView setImage:[UIImage imageNamed:@"logo_1536x2048"] forState:UIControlStateNormal];
    [_coverView setImage:[UIImage imageNamed:@"logo_1536x2048"] forState:UIControlStateHighlighted];
    [_coverView addTarget:self action:@selector(GetImageFromCameraBtnTapped) forControlEvents:UIControlEventTouchUpInside];
    if (    self.interfaceOrientation == UIInterfaceOrientationLandscapeLeft || self.interfaceOrientation == UIInterfaceOrientationLandscapeRight)
    {
        _coverView.center = CGPointMake([UIScreen mainScreen].bounds.size.height/2.0, [UIScreen mainScreen].bounds.size.width/2.0);
    }
    else
    {
        _coverView.center = CGPointMake([UIScreen mainScreen].bounds.size.width/2.0, [UIScreen mainScreen].bounds.size.height/2.0);
    }
    [self.view addSubview:_coverView];
    [self GetImageFromCameraBtnTapped];
    /**chg by viziner jym **/


    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(orientationChanged:) name:@"UIDeviceOrientationDidChangeNotification" object:nil];
}
/**chg by viziner jym **/
- (void)viewWillAppear:(BOOL)animated
{
    if (self.interfaceOrientation == UIInterfaceOrientationLandscapeLeft || self.interfaceOrientation == UIInterfaceOrientationLandscapeRight)
    {
        _coverView.center = CGPointMake([UIScreen mainScreen].bounds.size.height/2.0, [UIScreen mainScreen].bounds.size.width/2.0);
    }
    else
    {
        _coverView.center = CGPointMake([UIScreen mainScreen].bounds.size.width/2.0, [UIScreen mainScreen].bounds.size.height/2.0);
    }
    [super viewWillAppear:animated];
}
/**chg by viziner jym **/

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) orientationChanged:(NSNotification *)notification
{
    if (picker == nil)
        return;
    
    UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
    if((orientation == UIDeviceOrientationLandscapeLeft) ||
       (orientation == UIDeviceOrientationLandscapeRight))
    {
        [picker.cameraOverlayView setFrame:
                CGRectMake(MAX(self.view.center.x-80, self.view.center.y-80),
                           MIN(self.view.center.x-80, self.view.center.y-80),
                           160, 160)];
    }
    else if(orientation == UIDeviceOrientationPortrait)
    {
        [picker.cameraOverlayView setFrame:
         CGRectMake(MIN(self.view.center.x-80, self.view.center.y-80),
                    MAX(self.view.center.x-80, self.view.center.y-80),
                    160, 160)];
    }
}

- (void) changeNumber {
    count--;
    if (numberView == nil)
        return;
    
    if (!count) {
        picker.cameraOverlayView = nil;
        numberView = nil;
        [picker takePicture];
        return;
    }

    [numberView setText:[NSString stringWithFormat:@"%d", count]];
    [self performSelector:@selector(changeNumber) withObject:nil afterDelay:2.0f];
}

- (void)GetImageFromCameraBtnTapped {
    //// Get Image Data
    picker = [[UIImagePickerController alloc] init];
   
    UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
    if((orientation == UIDeviceOrientationLandscapeLeft) ||
         (orientation == UIDeviceOrientationLandscapeRight))
    {
        numberView = [[UITextView alloc]
                      initWithFrame:CGRectMake(MAX(self.view.center.x-80, self.view.center.y-80),
                                               MIN(self.view.center.x-80, self.view.center.y-80),
                                               160, 160)];
    }
    else
    {
        numberView = [[UITextView alloc]
                      initWithFrame:CGRectMake(MIN(self.view.center.x-80, self.view.center.y-80),
                                               MAX(self.view.center.x-80, self.view.center.y-80),
                                               160, 160)];
    }
    
    numberView.backgroundColor = [UIColor clearColor];
    numberView.textColor = [UIColor redColor];
    [numberView setFont:[UIFont boldSystemFontOfSize:100.0f]];
    numberView.textAlignment = NSTextAlignmentCenter;
    count = 3;
    [numberView setText:[NSString stringWithFormat:@"%d", count]];
    
    picker.delegate = self;
    picker.allowsEditing = YES;
    picker.sourceType = UIImagePickerControllerSourceTypeCamera;
    picker.cameraOverlayView = numberView;
    
    [self presentViewController:picker animated:YES completion:^{
        [self performSelector:@selector(changeNumber) withObject:nil afterDelay:2.0f];
    }];
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if (capturedImage != NULL) {
        ImageBrowserViewController *imgBrowViewCtrl = segue.destinationViewController;
        imgBrowViewCtrl.realImage = capturedImage;
    }
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    UIImage *tempImage = info[UIImagePickerControllerEditedImage];
    capturedImage = tempImage;
    
    [picker dismissViewControllerAnimated:YES completion:NULL];
    
    // go to image browser page
    [self performSegueWithIdentifier:@"GotoImageBrowserSeque" sender:self];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    numberView = nil;
    [picker dismissViewControllerAnimated:YES completion:NULL];
}

-(BOOL)shouldAutorotate {
    return YES;
}

-(NSUInteger)supportedInterfaceOrientations{
    return UIInterfaceOrientationMaskAll;
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    _coverView.frame = [UIScreen mainScreen].bounds;
    _coverView.center = self.view.center;
}

@end
