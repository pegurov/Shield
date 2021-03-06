//
//  ShieldViewController.m
//  SHIELD
//
//  Created by Pavel Gurov on 04/04/15.
//  Copyright (c) 2015 Andrey Ogrenich. All rights reserved.
//

#import "ShieldViewController.h"
#import "PairedShieldConnectingViewController.h"

@interface ShieldViewController () <BTManagerDelegate, ShieldDelegate, PairedShieldVCDelegate>

@property (weak, nonatomic) IBOutlet UISwitch *switchIsWorking;
@property (weak, nonatomic) IBOutlet UIView *viewContainer;

@property (weak, nonatomic) IBOutlet UILabel *labelMode;
@property (weak, nonatomic) IBOutlet UILabel *labelHeat;
@property (weak, nonatomic) IBOutlet UILabel *labelTemperature;
@property (weak, nonatomic) IBOutlet UILabel *labelBatteryLevel;
@property (weak, nonatomic) IBOutlet UILabel *labelIsCharging;

@property (weak, nonatomic) IBOutlet UISegmentedControl *segmentedControlMode;

// manual view
@property (weak, nonatomic) IBOutlet UIView *viewManual;
@property (weak, nonatomic) IBOutlet UILabel *labelManualHeat;
@property (weak, nonatomic) IBOutlet UISlider *sliderManualHeat;

// auto view
@property (weak, nonatomic) IBOutlet UIView *viewAuto;

//
@property (strong, nonatomic) PairedShieldConnectingViewController *pairedVC;

// user actions
- (IBAction)segmentedControlValueChanged:(UISegmentedControl *)sender;
- (IBAction)switchValueChanged:(UISwitch *)sender;
- (IBAction)sliderManualHeatValueChanged:(UISlider *)sender;
- (IBAction)sliderManualEndedTouch:(UISlider *)sender;
@end

@implementation ShieldViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    UIBarButtonItem *disconnectButton = [[UIBarButtonItem alloc] initWithTitle:@"Unpair" style:UIBarButtonItemStylePlain target:self action:@selector(disconnectTap)];
    [self.navigationItem setRightBarButtonItem:disconnectButton];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(checkToShowPairedVC) name:UIApplicationWillEnterForegroundNotification object:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [BTManager sharedInstance].delegate = self;
    Shield *connectedShield = [BTManager sharedInstance].connectedShield;
    self.title = connectedShield.peripheral.name;
    [connectedShield setDelegate:self];
    
    [self refreshViewSettingShieldValuesToControls:YES];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [BTManager sharedInstance].delegate = self;
    
    [self checkToShowPairedVC];
    [self refreshViewSettingShieldValuesToControls:YES];
}

- (void)checkToShowPairedVC {
    Shield *connectedShield = [BTManager sharedInstance].connectedShield;
    
    [self.pairedVC.view removeFromSuperview];
    [self.pairedVC removeFromParentViewController];
    self.pairedVC = nil;
    
    if (connectedShield) {
        [connectedShield setDelegate:self];
    }
    else {
        self.pairedVC = [self.storyboard instantiateViewControllerWithIdentifier:@"PairedShieldConnectingViewController"];
        self.pairedVC.delegate = self;
        [self addChildViewController:self.pairedVC];
        [self.view addSubview:self.pairedVC.view];
        [self.pairedVC viewDidAppear:NO];
        
    }
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
}

// -----------------------------------------------------------------
#pragma mark - PairedShieldVCDelegate

- (void)didFinish {
    [self viewDidAppear:NO];
}

// -----------------------------------------------------------------
#pragma mark - BTManagerDelegate

- (void)btManagerDidDisconnectFromShield:(BTManager *)manager {

    NSString *pairedUUID = [[NSUserDefaults standardUserDefaults] objectForKey:DEF_KEY_PAIRED_SHIELD_UUID];
    if (pairedUUID) {
        self.pairedVC = [self.storyboard instantiateViewControllerWithIdentifier:@"PairedShieldConnectingViewController"];
        self.pairedVC.delegate = self;
        [self addChildViewController:self.pairedVC];
        [self.view addSubview:self.pairedVC.view];
        [self.pairedVC viewDidAppear:NO];
    }
    else {
        [self.navigationController popToRootViewControllerAnimated:YES];
    }
}

// -----------------------------------------------------------------
#pragma mark - ShieldDelegate

- (void)shieldDidUpdate:(Shield *)shield {
    [self refreshViewSettingShieldValuesToControls:NO];
}

// -----------------------------------------------------------------
#pragma mark - View refreshing

- (void)refreshViewSettingShieldValuesToControls:(BOOL)setting {
    
    Shield *connectedShield = [BTManager sharedInstance].connectedShield;
    if (connectedShield) {
        self.title = connectedShield.peripheral.name;
    }
    else {
        self.title = [[NSUserDefaults standardUserDefaults] objectForKey:DEF_KEY_PAIRED_SHIELD_NAME];
    }
    
    if (connectedShield.isOn) {
        [self.viewContainer setHidden:NO];
        
        [self.labelMode setText:(connectedShield.mode == ShieldModeManual)? @"Manual" : @"Auto"];
        [self.labelHeat setText:[NSString stringWithFormat:@"%@", @(connectedShield.heat)]];
        [self.labelTemperature setText:[NSString stringWithFormat:@"%.01f", connectedShield.temperature]];
        [self.labelIsCharging setText:[NSString stringWithFormat:@"%@", connectedShield.isCharging? @"YES" : @"NO"]];
        [self.labelBatteryLevel setText:[NSString stringWithFormat:@"%@", @(connectedShield.batteryLevel)]];
        
        if (connectedShield.mode == ShieldModeManual) { // manual
            [self.viewManual setHidden:NO];
            [self.viewAuto setHidden:YES];
        }
        else { // auto
            [self.viewManual setHidden:YES];
            [self.viewAuto setHidden:NO];
        }
    }
    else {
        [self.viewContainer setHidden:YES];
    }
    
    if (setting) {
        self.switchIsWorking.on = connectedShield.isOn;
        [self.segmentedControlMode setSelectedSegmentIndex:(connectedShield.mode == ShieldModeManual)? 0 : 1];
        [self.labelManualHeat setText:[NSString stringWithFormat:@"%@", @(connectedShield.heat)]];
        [self.sliderManualHeat setValue:((float)connectedShield.heat/100.) animated:YES];
    }
}

// -----------------------------------------------------------------
#pragma mark - User actions

- (IBAction)segmentedControlValueChanged:(UISegmentedControl *)sender {
    [self.viewAuto setHidden:YES];
    [self.viewManual setHidden:YES];
    
    ShieldMode selectedMode = sender.selectedSegmentIndex == 0 ? ShieldModeManual : ShieldModeAuto;
    [[BTManager sharedInstance] setMode:selectedMode сompletionBlock:^(BOOL successful) {
        [self refreshViewSettingShieldValuesToControls:YES];
    }];
}

- (IBAction)switchValueChanged:(UISwitch *)sender {
    self.switchIsWorking.enabled = NO;
    self.viewContainer.userInteractionEnabled = NO;

    NSString *setAFTC = sender.isOn? @"AT+AFTC3FF" : @"AT+AFTC000";
    NSString *setAFTCresponse = sender.isOn? @"OK+Set:3FF" : @"OK+Set:000";
    
    NSString *setPIOCommand = sender.isOn? @"AT+PIO21" : @"AT+PIO20";
    NSString *setPIOResponse = sender.isOn? @"OK+PIO2:1" : @"OK+PIO2:0";

    [[BTManager sharedInstance] sendATCommandToHM11:setAFTC timeout:2 completionBlock:^(BOOL successful, NSString *response) {
        if (successful) {
            if ([response isEqualToString:setAFTCresponse]) {
                
                [[BTManager sharedInstance] sendATCommandToHM11:setPIOCommand timeout:2 completionBlock:^(BOOL successful, NSString *response) {
                    if (successful) {
                        if ([response isEqualToString:setPIOResponse]) {
                            // success
                            [BTManager sharedInstance].connectedShield.isOn = self.switchIsWorking.on;
                            if ([BTManager sharedInstance].connectedShield.isOn) {
                                [[BTManager sharedInstance] getStateWithCompletionBlock:^(BOOL successful) {
                                    if (successful) {
                                        self.switchIsWorking.enabled = YES;
                                        self.viewContainer.userInteractionEnabled = YES;
                                        [self refreshViewSettingShieldValuesToControls:YES];
                                    }
                                    else {
                                        [self unsuccessfulModeChangeHandler];
                                    }
                                }];
                            }
                            else {
                                self.switchIsWorking.enabled = YES;
                                self.viewContainer.userInteractionEnabled = YES;
                                [self refreshViewSettingShieldValuesToControls:YES];
                            }
                        }
                        else {
                            [self unsuccessfulModeChangeHandler];
                        }
                    }
                    else {
                        [self unsuccessfulModeChangeHandler];
                    }
                }];
            }
            else {
                [self unsuccessfulModeChangeHandler];
            }
        }
        else {
            [self unsuccessfulModeChangeHandler];
        }
    }];
}

- (void)unsuccessfulModeChangeHandler {
    self.switchIsWorking.enabled = YES;
    self.viewContainer.userInteractionEnabled = YES;
    [self refreshViewSettingShieldValuesToControls:NO];
    self.switchIsWorking.on = !self.switchIsWorking.on;
}

- (IBAction)sliderManualHeatValueChanged:(UISlider *)sender {
    [self.labelManualHeat setText:[NSString stringWithFormat:@"%d", (int)(100*sender.value)]];
}

- (IBAction)sliderManualEndedTouch:(UISlider *)sender {
    [[BTManager sharedInstance] setHeat:(int)(100*sender.value) сompletionBlock:^(BOOL successful) { }];
}

- (void)disconnectTap {
    self.viewContainer.alpha = 0.5;
    [self.view setUserInteractionEnabled:NO];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:DEF_KEY_PAIRED_SHIELD_UUID];
    [[BTManager sharedInstance] disconnectFromConnectedShield];
}

@end
