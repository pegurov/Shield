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
#import "BTManager.h"

#define ELLIPSE_RIGHT_OFFSET 170.
#define MAXIMUM_OFFSET 30.

@interface ShieldViewController () <BTManagerDelegate>

@property (weak, nonatomic) IBOutlet UISegmentedControl *segmentedControlMode;

@property (nonatomic) CGPoint initialPanCenter;
@property (nonatomic) CGPoint currentPanCenter;

@property (weak, nonatomic) IBOutlet UIView *viewBlack;
@property (weak, nonatomic) IBOutlet UIView *viewLabels;
@property (weak, nonatomic) IBOutlet UIImageView *imageViewBlurredLabels;

@property (weak, nonatomic) IBOutlet UILabel *labelSetHeatPercent;
@property (weak, nonatomic) IBOutlet UILabel *labelSetTime;
@property (weak, nonatomic) IBOutlet UILabel *labelCurrentBatteryLevel;

@property (weak, nonatomic) IBOutlet UILabel *labelHeatPercent;
@property (weak, nonatomic) IBOutlet UILabel *labelTime;

@property (weak, nonatomic) IBOutlet UIImageView *imageViewHeatIndicator;
@property (weak, nonatomic) IBOutlet UIView *viewIndicatorDarkener;
@property (weak, nonatomic) IBOutlet UIView *viewLine;
@property (strong, nonatomic) IBOutlet UIPanGestureRecognizer *panGR;

@property (strong, nonatomic) NSTimer *updateTimer;

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

@property (nonatomic) CGFloat sliderValue;
@property (nonatomic) NSInteger batteryLevel;
@property (nonatomic) BOOL isCharging;

@property (weak, nonatomic) IBOutlet UIImageView *imageViewEllipse;
- (IBAction)viewPanned:(UIPanGestureRecognizer *)sender;
- (IBAction)disconnectTap:(id)sender;
@end

@implementation ShieldViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.segmentedControlMode addTarget:self action:@selector(valueChanged:) forControlEvents: UIControlEventValueChanged];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [[BTManager sharedInstance] setDelegate:self];

    [self.segmentedControlMode.layer setAnchorPoint:CGPointMake(0.65, 0.5)];
    [self.segmentedControlMode setTransform:CGAffineTransformMakeScale(1.5, 1.5)];

    // set default state
    [self updateBlurredImage];
    [self showEllipse:NO everythingElse:YES animated:YES];
    [self refreshViewOnShieldUpdated];
}

- (void)refreshViewOnShieldUpdated
{
    // current heat level
    NSInteger currentHeatLevel = [BTManager sharedInstance].connectedShield.heat;
    CGFloat x = self.view.frame.size.width/2.;
    CGFloat y = self.view.frame.size.height - ((self.view.frame.size.height - MAXIMUM_OFFSET*2)*(currentHeatLevel/100.) + MAXIMUM_OFFSET);
    [self setCurrentPanCenter:CGPointMake(x, y)];
    
    // current mode
    NSInteger currentMode = [BTManager sharedInstance].connectedShield.mode==ShieldModeManual? 0 : 1;
    [self.segmentedControlMode setSelectedSegmentIndex:currentMode];
    [self showEllipse:NO everythingElse:(currentMode==1) animated:NO];
    [self.panGR setEnabled:(currentMode==0)];
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
    self.sliderValue = (currentPanCenter.y - MAXIMUM_OFFSET) / (self.view.frame.size.height - MAXIMUM_OFFSET*2);
    self.sliderValue = (self.sliderValue < 0) ? 0 : self.sliderValue;
    self.sliderValue = (self.sliderValue > 1) ? 1 : self.sliderValue;
    
    
    [self updateLabels];
    [self updateBlurredImage];
}

- (void)updateLabels
{
    CGFloat heat = 100 * (1-self.sliderValue);
    NSInteger time = (heat == 0)? 240*60*(self.batteryLevel/100.) : (int)(8*60*(self.batteryLevel/100.));
    
    [self.labelSetHeatPercent setText:[NSString stringWithFormat:@"h %d\%%",(int)heat]];
    [self.labelSetTime setText:[NSString stringWithFormat:@"t %d:%02d",(int)(floorf(time/60)), (int)(time%60)]];
    
    [self.labelHeatPercent setText:[NSString stringWithFormat:@"heat %d\%%",(int)heat]];
    [self.labelTime setText:[NSString stringWithFormat:@"use %d:%02d",(int)(floorf(time/60)), (int)(time%60)]];
    
    NSString *isChargingString = self.isCharging? @", charging" : @"";
    [self.labelCurrentBatteryLevel setText:[NSString stringWithFormat:@"battery: %@%%%@", @(self.batteryLevel), isChargingString]];
}

//---------------------------------------------------------------------------
#pragma mark - User actions

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesBegan:touches withEvent:event];
    
    if (self.panGR.enabled) {
        UITouch *someTouch = [touches anyObject];
        
        if (someTouch) {
            self.currentPanCenter = [someTouch locationInView:self.view];
            [self showEllipse:YES everythingElse:NO animated:YES];
        }
    }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesEnded:touches withEvent:event];
    
    if (self.panGR.enabled) {
        [self showEllipse:NO everythingElse:YES animated:YES];
        [self writeCurrentHeatToShield];
    }
}

- (IBAction)viewPanned:(UIPanGestureRecognizer *)sender
{
    if (sender.state == UIGestureRecognizerStateBegan) {
        
        self.initialPanCenter = [sender locationInView:self.view];
        [self showEllipse:YES everythingElse:NO animated:YES];
        
    }
    
    if (sender.state == UIGestureRecognizerStateEnded ||
        sender.state == UIGestureRecognizerStateCancelled) {
        
        [self showEllipse:NO everythingElse:YES animated:YES];
        
        // WRITE TO SHIELD
        [self.updateTimer invalidate];
        [self writeCurrentHeatToShield];
    }
    
    CGFloat translationY = [sender translationInView:self.view].y;
    CGFloat translationX = [sender translationInView:self.view].x;
    
    
    CGPoint currentPanCenter = CGPointMake(self.initialPanCenter.x + translationX, self.initialPanCenter.y + translationY);
    currentPanCenter.y = (currentPanCenter.y > 0)? currentPanCenter.y : 0;
    currentPanCenter.y = (currentPanCenter.y < self.view.frame.size.height)? currentPanCenter.y : self.view.frame.size.height;
    
    self.currentPanCenter = currentPanCenter;
}

- (IBAction)disconnectTap:(id)sender
{
    [self.navigationController popToRootViewControllerAnimated:YES];
    [[BTManager sharedInstance] disconnectFromConnectedShield];
}

- (void)valueChanged:(UISegmentedControl *)segment
{
    [[BTManager sharedInstance] setMode:segment.selectedSegmentIndex];
}

- (void)writeCurrentHeatToShield
{
    [[BTManager sharedInstance] setHeat:(int)(100*(1-self.sliderValue))];
}

//---------------------------------------------------------------------------
#pragma mark - Helpers

// pass YES to show, NO to hide
- (void)showEllipse:(BOOL)showEllipse everythingElse:(BOOL)showEverythingElse animated:(BOOL)animated
{
    [self updateBlurredImage];
    
    CGFloat duration = animated ? 0.1 : 0;
    CGFloat ellipseAlpha = showEllipse? 1 : 0;
    CGFloat everythingElseAlpha = showEverythingElse? 1 : 0;
    
    [UIView animateWithDuration:duration animations:^{
        self.imageViewEllipse.alpha = ellipseAlpha;
        self.viewLine.alpha = ellipseAlpha;
        self.labelSetHeatPercent.alpha = ellipseAlpha;
        self.labelSetTime.alpha = ellipseAlpha;
        
//        [self.imageViewBlurredLabels setAlpha:everythingElseAlpha/4.];
//        [self.viewBlack setAlpha:everythingElseAlpha];
    }];
}

// ---------------------------------------------------------------------------
#pragma mark - BTManagerDelegate

- (void)btManagerDidDisconnectFromShield:(BTManager *)manager
{
    [self.navigationController popToRootViewControllerAnimated:YES];
}

- (void)btManagerConnectedShieldUpdated:(BTManager *)manager
{
    [self refreshViewOnShieldUpdated];
}

@end
