//
//  ResultViewController.h
//  HighlightImage
//
//  Created by nglayi on 4/21/14.
//  Copyright (c) 2014 hanayonghe. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ResultViewController : UIViewController <UIScrollViewDelegate>
{
    IBOutlet UIImageView *ResultImageView;
    IBOutlet UIButton *btnSave;
}

@property (nonatomic, retain) CIImage *resultImage;
- (IBAction)onSave:(id)sender;
@end