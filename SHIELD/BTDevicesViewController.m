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

@property (strong, nonatomic) NSArray *devices;
- (void)startLookingForDevices;

// IBOutlets
@property (weak, nonatomic) IBOutlet UITableView *tableView;

@end

@implementation BTDevicesViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self addActivityIndicatorToNavigationBar];
    
    // BT manager
    [[BTManager sharedInstance] setDelegate:self];
    [[BTManager sharedInstance] startScanning];
}

- (void)viewWillAppear:(BOOL)animated
{
    [self.navigationController setNavigationBarHidden:NO animated:animated];
    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [self.navigationController setNavigationBarHidden:YES animated:animated];
    [super viewWillDisappear:animated];
}

//------------------------------------------------------------------------------------
#pragma mark - BTManagerDelegate

-(void)didUpdateState:(BTManagerState)state
{
    if (state == BTManagerStateIsLooking) {
        [self.activityIndicatorNavigation startAnimating];
    }
    else {
        [self.activityIndicatorNavigation stopAnimating];
    }
}

- (void)discoveredChanged:(NSMutableArray *)discovered
{
    self.devices = discovered;
    [self.tableView reloadData];
}

- (void)connectedChanged:(NSMutableArray *)connected
{
    [self.tableView reloadData];
}

- (void)errorOccured:(NSError *)error
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"BTLE" message:@"Error occured" delegate:nil
                                          cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alert show];
}

//------------------------------------------------------------------------------------
#pragma mark - UITableView methods

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.devices count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    CBPeripheral *device = [self.devices objectAtIndex:indexPath.row];
    DeviceCell *cell = [tableView dequeueReusableCellWithIdentifier:[DeviceCell cellIdentifier] forIndexPath:indexPath];
    [cell setDevice:device];
    
    
    if (device.state == CBPeripheralStateConnected) {
        cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
    }
    else if (device.state == CBPeripheralStateConnecting) {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    else if (device.state == CBPeripheralStateDisconnected) {
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    [[BTManager sharedInstance] connectToDevice:[self.devices objectAtIndex:indexPath.row]];
    
//    self.selectedDevice = [self.devices objectAtIndex:indexPath.row];
//    [self performSegueWithIdentifier:SEGUE_ID_DEVICE_DETAIL sender:self];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:SEGUE_ID_DEVICE_DETAIL]) {
        ShieldViewController *nextVC = segue.destinationViewController;
        BTDevicesViewController *currentVC = segue.sourceViewController;
        nextVC.device = currentVC.selectedDevice;
    }
}

@end
