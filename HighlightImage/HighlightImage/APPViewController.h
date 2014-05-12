//
//  APPViewController.h
//  HighlightImage
//
//  Created by JiangJian on 19/4/14.
//  Copyright (c) 2014 hanayonghe. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface APPViewController : UIViewController  <UINavigationControllerDelegate, UIImagePickerControllerDelegate>
{
    UITextView *numberView;
    UIImagePickerController *picker;
    int count;
}
@end
