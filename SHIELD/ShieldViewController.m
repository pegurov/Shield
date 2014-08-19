//
//  ShieldViewController.m
//  SHIELD
//
//  Created by Pavel Gurov on 18/08/14.
//  Copyright (c) 2014 Andrey Ogrenich. All rights reserved.
//

#import "ShieldViewController.h"

@interface ShieldViewController ()
@property (nonatomic) CGPoint initialPanCenter;
@property (nonatomic) CGPoint currentPanCenter;

@property (weak, nonatomic) IBOutlet UILabel *labelSetHeatPercent;
@property (weak, nonatomic) IBOutlet UILabel *labelSetTime;
@property (weak, nonatomic) IBOutlet UIImageView *imageViewHeatIndicator;
@property (weak, nonatomic) IBOutlet UIView *viewIndicatorDarkener;
@property (weak, nonatomic) IBOutlet UIView *viewLine;
@property (strong, nonatomic) IBOutlet UIPanGestureRecognizer *panGR;

@property (weak, nonatomic) IBOutlet UIImageView *imageViewEllipse;
- (IBAction)viewPanned:(UIPanGestureRecognizer *)sender;
@end

@implementation ShieldViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self showEllipse:NO animated:NO];
}

//---------------------------------------------------------------------------
#pragma mark - Setters

- (void)setCurrentPanCenter:(CGPoint)currentPanCenter
{
    _currentPanCenter = currentPanCenter;
    
    // adjust position of the ellipse
    CGPoint ellipseCenter = self.imageViewEllipse.center;
    ellipseCenter.y = currentPanCenter.y;
    ellipseCenter.x = currentPanCenter.x;
    [self.imageViewEllipse setCenter:ellipseCenter];
    
    CGRect lineFrame = self.viewLine.frame;
    lineFrame.origin = CGPointMake(15, currentPanCenter.y-2);
    lineFrame.size = CGSizeMake(currentPanCenter.x-15, 1);
    [self.viewLine setFrame:lineFrame];
    
    CGRect indicatorDarkenerFrame = self.viewIndicatorDarkener.frame;
    indicatorDarkenerFrame.size = CGSizeMake(8, currentPanCenter.y);
    [self.viewIndicatorDarkener setFrame:indicatorDarkenerFrame];
    
    CGRect labelSetHeatFrame = self.labelSetHeatPercent.frame;
    labelSetHeatFrame.origin = CGPointMake(15, currentPanCenter.y - 25);
    [self.labelSetHeatPercent setFrame:labelSetHeatFrame];

    CGRect labelSetTimeFrame = self.labelSetTime.frame;
    labelSetTimeFrame.origin = CGPointMake(15, currentPanCenter.y );
    [self.labelSetTime setFrame:labelSetTimeFrame];
    
}

//---------------------------------------------------------------------------
#pragma mark - User actions

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *someTouch = [touches anyObject];
    
    if (someTouch) {
        self.currentPanCenter = [someTouch locationInView:self.view];
        [self showEllipse:YES animated:YES];
    }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self showEllipse:NO animated:YES];
}

- (IBAction)viewPanned:(UIPanGestureRecognizer *)sender
{
    if (sender.state == UIGestureRecognizerStateBegan) {
        
        self.initialPanCenter = [sender locationInView:self.view];
        [self showEllipse:YES animated:YES];
    }
    
    if (sender.state == UIGestureRecognizerStateEnded ||
        sender.state == UIGestureRecognizerStateCancelled) {
        
        [self showEllipse:NO animated:YES];
    }
    
    CGFloat translationY = [sender translationInView:self.view].y;
    CGFloat translationX = [sender translationInView:self.view].x;
    self.currentPanCenter = CGPointMake(self.initialPanCenter.x + translationX, self.initialPanCenter.y + translationY);
}

//---------------------------------------------------------------------------
#pragma mark - Helpers

// pass YES to show, NO to hide
- (void)showEllipse:(BOOL)show animated:(BOOL)animated
{
    CGFloat duration = animated ? 0.1 : 0;
    CGFloat alpha = show? 1 : 0;
    
    [UIView animateWithDuration:duration animations:^{
        self.imageViewEllipse.alpha = alpha;
        self.viewLine.alpha = alpha;
        self.labelSetHeatPercent.alpha = alpha;
        self.labelSetTime.alpha = alpha;
    }];
}

@end