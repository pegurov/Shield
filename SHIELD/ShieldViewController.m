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
    
    [[BTManager sharedInstance] setDelegate:self];
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
    UITouch *someTouch = [touches anyObject];
    
    if (someTouch) {
        self.currentPanCenter = [someTouch locationInView:self.view];
        [self showEllipse:YES animated:YES];
    }

//    [self writeToShield];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self showEllipse:NO animated:YES];
    [self writeToShield];
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
        
        
        // WRITE TO SHIELD
        [self.updateTimer invalidate];
        [self writeToShield];
    }
    
    CGFloat translationY = [sender translationInView:self.view].y;
    CGFloat translationX = [sender translationInView:self.view].x;
    
    
    CGPoint currentPanCenter = CGPointMake(self.initialPanCenter.x + translationX, self.initialPanCenter.y + translationY);
    currentPanCenter.y = (currentPanCenter.y > 0)? currentPanCenter.y : 0;
    currentPanCenter.y = (currentPanCenter.y < self.view.frame.size.height)? currentPanCenter.y : self.view.frame.size.height;
    
    self.currentPanCenter = currentPanCenter;
}

- (void)writeToShield
{
    // we need to write 2 times
    // first is command, then value
    
    unsigned char setHeatCommand = 0x65;
    unsigned char valueCommand = 0x64 * (1-self.sliderValue);
    
    [[BTManager sharedInstance] writeToConecttedShield:[NSMutableData dataWithBytes:&setHeatCommand length:sizeof(setHeatCommand)]];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [[BTManager sharedInstance] writeToConecttedShield:[NSMutableData dataWithBytes:&valueCommand length:sizeof(valueCommand)]];
    });
    
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

// ---------------------------------------------------------------------------
#pragma mark - BTManagerDelegate

- (void)btManagerDidDisconnectFromShield:(BTManager *)manager
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)btManager:(BTManager *)manager didReceiveData:(NSData *)data
{
    NSString *dataString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSScanner *scanner = [NSScanner scannerWithString:dataString];

    NSCharacterSet *digitsSet = [NSCharacterSet decimalDigitCharacterSet];
    NSCharacterSet *scanUpToSet = [[NSCharacterSet decimalDigitCharacterSet] invertedSet];
    NSMutableArray *scannedStrings = [NSMutableArray array];
    
    while (!scanner.isAtEnd) {
        
        NSString *scannedString = @"";
        [scanner scanUpToCharactersFromSet:scanUpToSet intoString:&scannedString];
        [scannedStrings addObject:scannedString];
        [scanner scanUpToCharactersFromSet:digitsSet intoString:nil];
    }
    
    NSLog(@"%@", scannedStrings);
    
    if (scannedStrings.count == 2) {
        
        NSInteger commandByte = [scannedStrings[0] integerValue];
        NSInteger valueByte = [scannedStrings[1] integerValue];
        
        if (commandByte == COMMAND_BATTERY_UPDATED) {
            self.batteryLevel = valueByte;
        }
        else if (commandByte == COMMAND_IS_CHARGING_UPDATED) {
            self.isCharging = (valueByte == 1) ? YES : NO;
        }
    }
    
    [self updateLabels];
}


//// ---------------------------------------------------------------------------
//#pragma mark - RBLProtocolDelegate
//
//- (void)protocolDidReceiveProtocolVersion:(uint8_t)major Minor:(uint8_t)minor Bugfix:(uint8_t)bugfix
//{
//    uint8_t buf[] = {'B', 'L', 'E'};
//    [self.protocol sendCustomData:buf Length:3];
//    [self.protocol queryTotalPinCount];
//}
//
//- (void)protocolDidReceiveTotalPinCount:(UInt8) count
//{
//    total_pin_count = count;
//    [self.protocol queryPinAll];
//}
//
//- (void)protocolDidReceivePinCapability:(uint8_t)pin Value:(uint8_t)value
//{
//    if (value == 0)
//        NSLog(@" - Nothing");
//    else
//    {
//        if (value & PIN_CAPABILITY_DIGITAL)
//            NSLog(@" - DIGITAL (I/O)");
//        if (value & PIN_CAPABILITY_ANALOG)
//            NSLog(@" - ANALOG");
//        if (value & PIN_CAPABILITY_PWM)
//            NSLog(@" - PWM");
//        if (value & PIN_CAPABILITY_SERVO)
//            NSLog(@" - SERVO");
//    }
//    
//    pin_cap[pin] = value;
//}
//
//- (void)protocolDidReceivePinData:(uint8_t)pin Mode:(uint8_t)mode Value:(uint8_t)value
//{
//    uint8_t _mode = mode & 0x0F;
//    
//    pin_mode[pin] = _mode;
//    if ((_mode == INPUT) || (_mode == OUTPUT))
//        pin_digital[pin] = value;
//    else if (_mode == ANALOG)
//        pin_analog[pin] = ((mode >> 4) << 8) + value;
//    else if (_mode == PWM)
//        pin_pwm[pin] = value;
//    else if (_mode == SERVO)
//        pin_servo[pin] = value;
//}
//
//- (void)protocolDidReceivePinMode:(uint8_t)pin Mode:(uint8_t)mode
//{
//    if (mode == INPUT)
//        NSLog(@" Pin %d Mode: INPUT", pin);
//    else if (mode == OUTPUT)
//        NSLog(@" Pin %d Mode: OUTPUT", pin);
//    else if (mode == PWM)
//        NSLog(@" Pin %d Mode: PWM", pin);
//    else if (mode == SERVO)
//        NSLog(@" Pin %d Mode: SERVO", pin);
//    
//    pin_mode[pin] = mode;
//}
//
//- (void)protocolDidReceiveCustomData:(UInt8 *)data length:(UInt8)length
//{
//    for (int i = 0; i< length; i++)
//        printf("0x%2X ", data[i]);
//    printf("\n");
//}

@end