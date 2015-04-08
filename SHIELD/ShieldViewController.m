//
//  ShieldViewController.m
//  SHIELD
//
//  Created by Pavel Gurov on 04/04/15.
//  Copyright (c) 2015 Andrey Ogrenich. All rights reserved.
//

#import "ShieldViewController.h"

@interface ShieldViewController () <BTManagerDelegate, ShieldDelegate>

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

// user actions
- (IBAction)segmentedControlValueChanged:(UISegmentedControl *)sender;
- (IBAction)sliderManualHeatValueChanged:(UISlider *)sender;
- (IBAction)sliderManualEndedTouch:(UISlider *)sender;
@end

@implementation ShieldViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self refreshValuesView];
    Shield *connectedShield = [BTManager sharedInstance].connectedShield;
    [self refreshControlsViewAfterModeChange:connectedShield.mode];
    
    UIBarButtonItem *disconnectButton = [[UIBarButtonItem alloc] initWithTitle:@"Disconnect" style:UIBarButtonItemStylePlain target:self action:@selector(disconnectTap)];
    [self.navigationItem setRightBarButtonItem:disconnectButton];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [BTManager sharedInstance].delegate = self;
    Shield *connectedShield = [BTManager sharedInstance].connectedShield;
    self.title = connectedShield.peripheral.name;
    [connectedShield setDelegate:self];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [BTManager sharedInstance].delegate = self;
    Shield *connectedShield = [BTManager sharedInstance].connectedShield;
    [connectedShield setDelegate:self];
}

// -----------------------------------------------------------------
#pragma mark - BTManagerDelegate

- (void)btManagerDidDisconnectFromShield:(BTManager *)manager
{
    [self.navigationController popToRootViewControllerAnimated:YES];
}

// -----------------------------------------------------------------
#pragma mark - ShieldDelegate

- (void)shieldDidUpdateMode:(Shield *)shield {
    [self refreshValuesView];
}

- (void)shieldDidUpdateHeat:(Shield *)shield {
    [self refreshValuesView];
}

- (void)shieldDidUpdateTemperature:(Shield *)shield {
    [self refreshValuesView];
}

- (void)shieldDidUpdateIsCharging:(Shield *)shield {
    [self refreshValuesView];
}

- (void)shieldDidUpdateBatteryLevel:(Shield *)shield {
    [self refreshValuesView];
}


// -----------------------------------------------------------------
#pragma mark - View refreshing

- (void)refreshValuesView {
    Shield *connectedShield = [BTManager sharedInstance].connectedShield;
    [self.labelMode setText:(connectedShield.mode == ShieldModeManual)? @"Manual" : @"Auto"];
    [self.labelHeat setText:[NSString stringWithFormat:@"%@", @(connectedShield.heat)]];
    [self.labelTemperature setText:[NSString stringWithFormat:@"%.01f", [connectedShield.temperature floatValue]]];
    [self.labelIsCharging setText:[NSString stringWithFormat:@"%@", connectedShield.isCharging? @"YES" : @"NO"]];
    [self.labelBatteryLevel setText:[NSString stringWithFormat:@"%@", @(connectedShield.batteryLevel)]];
}

- (void)refreshControlsViewAfterModeChange:(ShieldMode)mode {
    Shield *connectedShield = [BTManager sharedInstance].connectedShield;
    if (mode == ShieldModeManual) { // manual
        [self.segmentedControlMode setSelectedSegmentIndex:0];
        [self.viewManual setHidden:NO];
        [self.viewAuto setHidden:YES];
        [self.labelManualHeat setText:[NSString stringWithFormat:@"%@", @(connectedShield.heat)]];
        [self.sliderManualHeat setValue:((float)connectedShield.heat/100.) animated:YES];
    }
    else { // auto
        [self.segmentedControlMode setSelectedSegmentIndex:1];
        [self.viewManual setHidden:YES];
        [self.viewAuto setHidden:NO];
    }
}

// -----------------------------------------------------------------
#pragma mark - User actions

- (IBAction)segmentedControlValueChanged:(UISegmentedControl *)sender {
    ShieldMode selectedMode = sender.selectedSegmentIndex == 0 ? ShieldModeManual : ShieldModeAuto;
    [[BTManager sharedInstance] setMode:selectedMode];
    [self refreshControlsViewAfterModeChange:selectedMode];
}

- (IBAction)sliderManualHeatValueChanged:(UISlider *)sender {
    [self.labelManualHeat setText:[NSString stringWithFormat:@"%d", (int)(100*sender.value)]];
}

- (IBAction)sliderManualEndedTouch:(UISlider *)sender {
    [[BTManager sharedInstance] setHeat:(int)(100*sender.value)];
}

- (void)disconnectTap {
    [[BTManager sharedInstance] disconnectFromConnectedShield];
    [self.navigationController popToRootViewControllerAnimated:YES];
}

@end
