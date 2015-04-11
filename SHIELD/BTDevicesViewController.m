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

@interface BTDevicesViewController () <UITableViewDataSource, UITableViewDelegate, BTManagerDelegate>

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
        [self performSegueWithIdentifier:SEGUE_ID_DEVICE_DETAIL sender:self];
    }
    else if (indexPath.section == 1) {
        Shield *selectedShield = [[[BTManager sharedInstance] discoveredShields] objectAtIndex:indexPath.row];
        [[BTManager sharedInstance] disconnectFromConnectedShield];
        [[BTManager sharedInstance] connectToShield:selectedShield completionBlock:^(BOOL successful) {
            
            [self.tableView reloadData];
            if (successful) {
                
                [[BTManager sharedInstance] sendATCommandToHM11:@"AT+PIO2?" timeout:2 completionBlock:^(BOOL successful, NSString *response) {
                   
                    if (successful) {
                        if ([response isEqualToString:@"OK+PIO2:0"]) {
                            [BTManager sharedInstance].connectedShield.isOn = NO;
                            [self performSegueWithIdentifier:SEGUE_ID_DEVICE_DETAIL sender:self];
                        }
                        else if ([response isEqualToString:@"OK+PIO2:1"]) {
                            [BTManager sharedInstance].connectedShield.isOn = YES;
                            [[BTManager sharedInstance] getStateWithCompletionBlock:^(BOOL successful) {
                                [self performSegueWithIdentifier:SEGUE_ID_DEVICE_DETAIL sender:self];
                            }];
                        }
                        else {
#warning TODO - show alert
                        }
                    }
                    else {
#warning TODO - show alert
                    }
                }];
            }
            else {
#warning TODO - show alert
            }
        }];
    }
    [self.tableView reloadData];
}

- (IBAction)searchTap:(id)sender {
    [BTManager sharedInstance].discoveredShields = [NSMutableArray new];
    [self.tableView reloadData];
    [[BTManager sharedInstance] scanForShieldsForSeconds:10];
}

@end
