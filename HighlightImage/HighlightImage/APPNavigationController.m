//
//  APPNavigationController.m
//  HighlightImage
//
//  Created by JiangJian on 19/4/14.
//  Copyright (c) 2014 hanayonghe. All rights reserved.
//

#import "APPNavigationController.h"

@interface APPNavigationController () {

}

@end

@implementation APPNavigationController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}

-(BOOL)shouldAutorotate {
    return YES;
}

-(NSUInteger)supportedInterfaceOrientations{
    return [self.visibleViewController supportedInterfaceOrientations];
}

@end
