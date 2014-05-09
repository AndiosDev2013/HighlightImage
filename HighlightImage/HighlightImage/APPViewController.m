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
}

@end

@implementation APPViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    count = 0;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) changeNumber {
    count--;
    if (!count) {
        picker.cameraOverlayView = nil;
        return;
    }

    [numberView setText:[NSString stringWithFormat:@"%d", count]];
    [self performSelector:@selector(changeNumber) withObject:nil afterDelay:2.0f];
}
- (IBAction)GetImageFromCameraBtnTapped:(id)sender {
    //// Get Image Data
    picker = [[UIImagePickerController alloc] init];
    numberView = [[UITextView alloc]
                              initWithFrame:CGRectMake(self.view.center.x-80,
                                                       self.view.center.y-80,
                                                       160, 160)];
    numberView.backgroundColor = [UIColor clearColor];
    numberView.textColor = [UIColor redColor];
    [numberView setFont:[UIFont boldSystemFontOfSize:100.0f]];
    numberView.textAlignment = NSTextAlignmentCenter;
    count = 3;
    [numberView setText:[NSString stringWithFormat:@"%d", count]];
    [self performSelector:@selector(changeNumber) withObject:nil afterDelay:2.0f];
    
    picker.delegate = self;
    picker.allowsEditing = YES;
    picker.sourceType = UIImagePickerControllerSourceTypeCamera;
    picker.cameraOverlayView = numberView;
    
    [self presentViewController:picker animated:YES completion:NULL];
    //[self performSegueWithIdentifier:@"gotoBPushSegue" sender:self];
}

- (IBAction)GetImageFromGalleryBtnTapped:(id)sender {
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.delegate = self;
    picker.allowsEditing = YES;
    picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    
    [self presentViewController:picker animated:YES completion:NULL];
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

@end
