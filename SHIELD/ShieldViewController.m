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

@property (weak, nonatomic) IBOutlet UIView *viewBlack;
@property (weak, nonatomic) IBOutlet UIView *viewLabels;
@property (weak, nonatomic) IBOutlet UIImageView *imageViewBlurredLabels;

@property (weak, nonatomic) IBOutlet UILabel *labelSetHeatPercent;
@property (weak, nonatomic) IBOutlet UILabel *labelSetTime;

@property (weak, nonatomic) IBOutlet UILabel *labelHeatPercent;
@property (weak, nonatomic) IBOutlet UILabel *labelTime;

@property (weak, nonatomic) IBOutlet UIImageView *imageViewHeatIndicator;
@property (weak, nonatomic) IBOutlet UIView *viewIndicatorDarkener;
@property (weak, nonatomic) IBOutlet UIView *viewLine;
@property (strong, nonatomic) IBOutlet UIPanGestureRecognizer *panGR;


// constraints
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *constraintEllipseOriginX;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *constraintEllipseOriginY;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *constraintLineWidth;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *constraintLineOriginY;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *constraintLabelHeatOriginY;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *constraintLabelTemperatureOriginY;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *constraintIndicatorDarkenerHeight;


@property (nonatomic) BOOL isUpdatingImage;
@property (nonatomic) BOOL imageNeedsUpdate;

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
    [self updateBlurredImage];

    [self showEllipse:NO animated:NO];
    [self setCurrentPanCenter:CGPointMake(100, 100)];
}

- (void)updateBlurredImage
{
    if (!self.isUpdatingImage) {
        self.isUpdatingImage = YES;
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            
            CGSize imageSize = CGSizeMake(self.viewLabels.bounds.size.width, self.viewLabels.bounds.size.height);
            UIGraphicsBeginImageContext(imageSize);
            [self.viewLabels.layer renderInContext:UIGraphicsGetCurrentContext()];
            UIImage *viewImage = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();
            
            UIColor *tintColor = [UIColor clearColor];
            UIImage *blurredImage = [viewImage applyBlurWithRadius:5 tintColor:tintColor saturationDeltaFactor:1.8 maskImage:nil];

            // return to main queue
            dispatch_sync(dispatch_get_main_queue(), ^{

                self.isUpdatingImage = NO;
                [self.imageViewBlurredLabels setImage:blurredImage];
                
                if (self.imageNeedsUpdate) {
                    [self updateBlurredImage];
                    self.imageNeedsUpdate = NO;
                }
            });
        });
    }
    else {
        self.imageNeedsUpdate = YES;
    }
}


//---------------------------------------------------------------------------
#pragma mark - Setters

- (void)setCurrentPanCenter:(CGPoint)currentPanCenter
{
    NSLog(@"%@", NSStringFromCGPoint(currentPanCenter));
    
    _currentPanCenter = currentPanCenter;
    
    // adjust position of the ellipse
    self.constraintEllipseOriginX.constant = currentPanCenter.x - (self.imageViewEllipse.frame.size.width/2.);
    self.constraintEllipseOriginY.constant = currentPanCenter.y - (self.imageViewEllipse.frame.size.height/2.);
    
    // adjust position of the line
    self.constraintLineOriginY.constant = currentPanCenter.y-2;
    self.constraintLineWidth.constant = currentPanCenter.x-15;
    
    // labels
    self.constraintLabelTemperatureOriginY.constant = currentPanCenter.y;
    self.constraintLabelHeatOriginY.constant = currentPanCenter.y - 25;
    
    // darkener
    self.constraintIndicatorDarkenerHeight.constant = currentPanCenter.y-2;
    
    
    // set labels with values
    CGFloat percent = currentPanCenter.y / self.view.frame.size.height;
    CGFloat heat = 100 * (1-percent);
    NSInteger time = (int)(67.5*60 * percent) + (4.5*60); // minutes
    
    [self.labelSetHeatPercent setText:[NSString stringWithFormat:@"h %d\%%",(int)heat]];
    [self.labelSetTime setText:[NSString stringWithFormat:@"t %d:%02d",(int)(floorf(time/60)), (int)(time%60)]];
    
    [self.labelHeatPercent setText:[NSString stringWithFormat:@"heat %d\%%",(int)heat]];
    [self.labelTime setText:[NSString stringWithFormat:@"use %d:%02d",(int)(floorf(time/60)), (int)(time%60)]];
    
    [self updateBlurredImage];
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
    [self updateBlurredImage];
    
    CGFloat duration = animated ? 0.1 : 0;
    CGFloat alpha = show? 1 : 0;
    
    [UIView animateWithDuration:duration animations:^{
        self.imageViewEllipse.alpha = alpha;
        self.viewLine.alpha = alpha;
        self.labelSetHeatPercent.alpha = alpha;
        self.labelSetTime.alpha = alpha;
        
        [self.imageViewBlurredLabels setAlpha:alpha/4.];
        [self.viewBlack setAlpha:alpha];
    }];
}

@end