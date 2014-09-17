//
//  CommonViewController.m
//  SHIELD
//
//  Created by Pavel Gurov on 18/08/14.
//  Copyright (c) 2014 Andrey Ogrenich. All rights reserved.
//

#import "CommonViewController.h"

@interface CommonViewController ()

@end

@implementation CommonViewController

// navigation activity indicator
- (void)addActivityIndicatorToNavigationBar
{
    self.activityIndicatorNavigation = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    [self.activityIndicatorNavigation setHidesWhenStopped:YES];
    [self.activityIndicatorNavigation setColor:[UIColor blackColor]];
    
    UIView *placeholder = [[UIView alloc] initWithFrame:CGRectMake(0., 0., 44, 44)];
    [placeholder addSubview:self.activityIndicatorNavigation];
    [self.activityIndicatorNavigation setCenter:CGPointMake(placeholder.frame.size.width/2., placeholder.frame.size.height/2.)];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:placeholder];
}

@end
