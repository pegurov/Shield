//
//  PairedShieldConnectingViewController.m
//  SHIELD
//
//  Created by Pavel Gurov on 12/04/15.
//  Copyright (c) 2015 Andrey Ogrenich. All rights reserved.
//

#import "PairedShieldConnectingViewController.h"
#import <MBProgressHUD.h>

@interface PairedShieldConnectingViewController () <BTManagerDelegate>
@property (weak, nonatomic) IBOutlet UILabel *labelTitle;
@property (weak, nonatomic) IBOutlet UIButton *buttonTryAgain;
@property (strong, nonatomic) MBProgressHUD *hud;

- (IBAction)tryAgainTap:(UIButton *)sender;
@end

@implementation PairedShieldConnectingViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [BTManager sharedInstance].delegate = self;
    [self showControls:NO];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [BTManager sharedInstance].delegate = self;
    [[BTManager sharedInstance] scanForShieldsForSeconds:10.];
}

- (void)showControls:(BOOL)show {
    self.labelTitle.hidden = !show;
    self.buttonTryAgain.hidden = !show;
}

- (IBAction)tryAgainTap:(UIButton *)sender {
    [[BTManager sharedInstance] scanForShieldsForSeconds:10];
}

//------------------------------------------------------------------------------
#pragma mark - BTManagerDelegate

- (void)btManagerUpdatedDiscoveredShields:(BTManager *)manager {
    NSString *pairedUUID = [[NSUserDefaults standardUserDefaults] objectForKey:DEF_KEY_PAIRED_SHIELD_UUID];
    for (Shield *someShield in [BTManager sharedInstance].discoveredShields) {
        if ([someShield.peripheral.identifier.UUIDString isEqualToString:pairedUUID]) {
            // found paired shield
            [[BTManager sharedInstance] disconnectFromConnectedShield];
            [[BTManager sharedInstance] connectToShield:someShield completionBlock:^(BOOL successful) {
                if (successful) {
                    [self proceed];
                }
                else {
                    [self showControls:YES];
                    [MBProgressHUD hideAllHUDsForView:self.navigationController.view animated:YES];
                }
            }];

        }
    }
}

- (void)proceed {
    [BTManager sharedInstance].connectedShield.passwordValidated = YES;
    [[BTManager sharedInstance] performActionsBeforeShowingShieldWithCompletionBlock:^(BOOL successful) {
        if (successful) {
            [[BTManager sharedInstance] stopScanningForShields];
            [MBProgressHUD hideAllHUDsForView:self.navigationController.view animated:YES];
            if ([self.delegate respondsToSelector:@selector(didFinish)]) {
                [self.delegate didFinish];
            }
        }
        else {
#warning SHOW ALERT
        }
    }];
}

- (void)btManagerDidStartScanningForShields:(BTManager *)manager {
    [self showControls:NO];
    self.hud = [MBProgressHUD showHUDAddedTo:self.navigationController.view animated:YES];
    self.hud.mode = MBProgressHUDModeIndeterminate;
    self.hud.dimBackground = YES;
    self.hud.labelText = @"Connecting";
}

- (void)btManagerDidEndScanningForShields:(BTManager *)manager {
    [MBProgressHUD hideAllHUDsForView:self.navigationController.view animated:YES];
    [self showControls:YES];
}

@end
