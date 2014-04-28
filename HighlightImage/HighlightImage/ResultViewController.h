//
//  ResultViewController.h
//  HighlightImage
//
//  Created by nglayi on 4/21/14.
//  Copyright (c) 2014 hanayonghe. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ResultViewController : UIViewController
{
    IBOutlet UIImageView *ResultImageView;
}

@property (nonatomic, retain) CIImage *resultImage;

@end