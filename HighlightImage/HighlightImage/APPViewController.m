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
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)GetImageFromCameraBtnTapped:(id)sender {
    //// Get Image Data
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.delegate = self;
    picker.allowsEditing = YES;
    picker.sourceType = UIImagePickerControllerSourceTypeCamera;
    
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
