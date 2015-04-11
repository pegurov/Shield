//
//  ViewController.m
//  Tester
//
//  Created by Andrey Ogrenich on 29/07/14.
//  Copyright (c) 2014 Andrey Ogrenich. All rights reserved.
//

#import "BTDevicesViewController.h"
#import "BTManager.h"
#import "DeviceCell.h"
#import "ShieldViewController.h"

@interface BTDevicesViewController () <UITableViewDataSource, UITableViewDelegate, BTManagerDelegate, UIAlertViewDelegate>

// IBOutlets
@property (weak, nonatomic) IBOutlet UIView *viewSearch;
@property (weak, nonatomic) IBOutlet UIButton *buttonSearch;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
- (IBAction)searchTap:(id)sender;
@end

@implementation BTDevicesViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Devices";
    
    NSString *pairedShieldUUID = [[NSUserDefaults standardUserDefaults] objectForKey:DEF_KEY_PAIRED_SHIELD_UUID];
    if (pairedShieldUUID) {
        [self performSegueWithIdentifier:SEGUE_ID_DEVICE_DETAIL_NO_ANIMATION sender:self];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self.tableView deselectRowAtIndexPath:self.tableView.indexPathForSelectedRow animated:YES];
    [[BTManager sharedInstance] setDelegate:self];
    [BTManager sharedInstance].discoveredShields = [NSMutableArray new];
    [[BTManager sharedInstance] scanForShieldsForSeconds:10.];
    
    [self.tableView reloadData];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [BTManager sharedInstance].delegate = self;
}

//------------------------------------------------------------------------------------
#pragma mark - BTManagerDelegate

- (void)btManagerDidStartScanningForShields:(BTManager *)manager {
    [self.activityIndicator startAnimating];
    [self.viewSearch setUserInteractionEnabled:NO];
    [self.viewSearch setAlpha:0.75];
    [self.buttonSearch setTitle:@"Searching" forState:UIControlStateNormal];
}

- (void)btManagerDidEndScanningForShields:(BTManager *)manager {
    [self.activityIndicator stopAnimating];
    [self.viewSearch setUserInteractionEnabled:YES];
    [self.viewSearch setAlpha:1];
    [self.buttonSearch setTitle:@"Search" forState:UIControlStateNormal];
}

- (void)btManagerUpdatedDiscoveredShields:(BTManager *)manager {
    [self.tableView reloadData];
}

- (void)btManager:(BTManager *)manager errorOccured:(NSError *)error {
    [self.activityIndicator stopAnimating];
    [self.viewSearch setUserInteractionEnabled:YES];
    [self.buttonSearch setTitle:@"Search" forState:UIControlStateNormal];
}

- (void)btManagerDidDisconnectFromShield:(BTManager *)manager {
    [self.tableView reloadData];
}

//------------------------------------------------------------------------------------
#pragma mark - UITableView methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        return [BTManager sharedInstance].connectedShield? 1 : 0;
    }
    else if (section == 1) {
        return [[BTManager sharedInstance] discoveredShields].count;
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    Shield *device;
    if (indexPath.section == 0) {
        device = [BTManager sharedInstance].connectedShield;
    }
    else {
        device = [[[BTManager sharedInstance] discoveredShields] objectAtIndex:indexPath.row];
    }
    
    DeviceCell *cell = [tableView dequeueReusableCellWithIdentifier:[DeviceCell cellIdentifier] forIndexPath:indexPath];
    [cell setDevice:device];
        
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        if ([BTManager sharedInstance].connectedShield.passwordValidated) {
            [self performSegueWithIdentifier:SEGUE_ID_DEVICE_DETAIL sender:self];
        }
        else {
            [self validatePasswordForShield:[BTManager sharedInstance].connectedShield];
        }
    }
    else if (indexPath.section == 1) {
        Shield *selectedShield = [[[BTManager sharedInstance] discoveredShields] objectAtIndex:indexPath.row];
        [self.tableView reloadData];
        [[BTManager sharedInstance] disconnectFromConnectedShield];
        [[BTManager sharedInstance] connectToShield:selectedShield completionBlock:^(BOOL successful) {
            [self.tableView reloadData];
            if (successful) {
                [self validatePasswordForShield:[BTManager sharedInstance].connectedShield];
            }
            else {
#warning TODO - show alert
            }
        }];
    }
    [self.tableView reloadData];
}

- (void)validatePasswordForShield:(Shield *)shield {
    [[BTManager sharedInstance] sendATCommandToHM11:@"AT+PASS?" timeout:2 completionBlock:^(BOOL successful, NSString *response) {
        
        if ([response isEqualToString:@"OK+Get:000000"]) { // there is no password
            [self proceedToShield:shield];
        }
        else { // need to enter password
            shield.password = [response substringFromIndex:7.];
            [self presentPasswordAlert];
        }
        [self.tableView reloadData];
    }];
}

- (void)presentPasswordAlert {
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Password confirmation" message:@"To connect to this Shield, you need to eneter password" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"OK", nil];
    alertView.tag = 1234;
    alertView.alertViewStyle = UIAlertViewStylePlainTextInput;
    UITextField *passwordTextField = [alertView textFieldAtIndex:0];
    passwordTextField.keyboardType = UIKeyboardTypeNumberPad;
    
    [alertView show];
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (alertView.tag == 1234) {
        // password
        switch (buttonIndex) {
            case 0: { // cancel
                break;
            }
            case 1: { // confirmed
                
                UITextField *passwordTextField = [alertView textFieldAtIndex:0];
                if (passwordTextField.text && [passwordTextField.text isEqualToString:[BTManager sharedInstance].connectedShield.password]) {
                    [self proceedToShield:[BTManager sharedInstance].connectedShield];
                }
                else {
                    // show alert that password is wrong
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Wrong passcode" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                    [alert show];
                }
                break;
            }
            default: { }
                break;
        }
    }
}

- (void)proceedToShield:(Shield *)shield {
    shield.passwordValidated = YES;
    [[BTManager sharedInstance] performActionsBeforeShowingShieldWithCompletionBlock:^(BOOL successful) {
        if (successful) {
            NSString *UUID = [[BTManager sharedInstance].connectedShield.peripheral identifier].UUIDString;
            [[NSUserDefaults standardUserDefaults] setObject:UUID forKey:DEF_KEY_PAIRED_SHIELD_UUID];
            [self performSegueWithIdentifier:SEGUE_ID_DEVICE_DETAIL sender:self];
        }
        else {
#warning SHOW ALERT
        }
    }];    
}

- (IBAction)searchTap:(id)sender {
    [BTManager sharedInstance].discoveredShields = [NSMutableArray new];
    [self.tableView reloadData];
    [[BTManager sharedInstance] scanForShieldsForSeconds:10];
}

@end
