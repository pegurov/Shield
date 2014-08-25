//
//  ShieldViewController.m
//  SHIELD
//
//  Created by Pavel Gurov on 18/08/14.
//  Copyright (c) 2014 Andrey Ogrenich. All rights reserved.
//

#import "ShieldViewController.h"
#import "UIImage+ImageEffects.h"
#import "GeneralHelper.h"

#define ELLIPSE_RIGHT_OFFSET 170.

@interface ShieldViewController ()
@property (nonatomic) CGPoint initialPanCenter;
@property (nonatomic) CGPoint currentPanCenter;

@property (weak, nonatomic) IBOutlet UIView *viewLabels;
@property (weak, nonatomic) IBOutlet UIImageView *imageViewBlurredLabels;

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
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    CGSize imageSize = CGSizeMake(self.viewLabels.bounds.size.width, self.viewLabels.bounds.size.height);
    UIGraphicsBeginImageContext(imageSize);
    [self.viewLabels.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *viewImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    UIColor *tintColor = [UIColor clearColor]; //[UIColor colorWithWhite:0.11 alpha:0.73];
    UIImage *blurredImage = [viewImage applyBlurWithRadius:5 tintColor:tintColor saturationDeltaFactor:1.8 maskImage:nil];
    
    [self.imageViewBlurredLabels setImage:blurredImage];
    [self showEllipse:NO animated:NO];
    
    [self setCurrentPanCenter:CGPointMake(100, 100)];
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
    indicatorDarkenerFrame.origin = CGPointMake(0, 0);
    indicatorDarkenerFrame.size = CGSizeMake(8, currentPanCenter.y-2);
    [self.viewIndicatorDarkener setFrame:indicatorDarkenerFrame];
    
    CGRect labelSetHeatFrame = self.labelSetHeatPercent.frame;
    labelSetHeatFrame.origin = CGPointMake(15, currentPanCenter.y - 25);
    [self.labelSetHeatPercent setFrame:labelSetHeatFrame];

    CGRect labelSetTimeFrame = self.labelSetTime.frame;
    labelSetTimeFrame.origin = CGPointMake(15, currentPanCenter.y );
    [self.labelSetTime setFrame:labelSetTimeFrame];
    
    // set labels with values
    CGFloat percent = currentPanCenter.y / self.view.frame.size.height;
    CGFloat heat = 100 * (1-percent);
    NSInteger time = (int)(67.5*60 * percent) + (4.5*60); // minutes
    
    [self.labelSetHeatPercent setText:[NSString stringWithFormat:@"h %d\%%",(int)heat]];
    [self.labelSetTime setText:[NSString stringWithFormat:@"t %d:%02d",(int)(floorf(time/60)), (int)(time%60)]];
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
    
    
    CGPoint currentPanCenter = CGPointMake(self.initialPanCenter.x + translationX, self.initialPanCenter.y + translationY);
    currentPanCenter.y = (currentPanCenter.y > 0)? currentPanCenter.y : 0;
    currentPanCenter.y = (currentPanCenter.y < self.view.frame.size.height)? currentPanCenter.y : self.view.frame.size.height;
    
    self.currentPanCenter = currentPanCenter;
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
        
        [self.imageViewBlurredLabels setAlpha:alpha/4.];
        [self.viewLabels setAlpha:(1-alpha)];
    }];
}

@end