//
//  ViewController.m
//  Tester
//
//  Created by Andrey Ogrenich on 29/07/14.
//  Copyright (c) 2014 Andrey Ogrenich. All rights reserved.
//

#import "ViewController.h"
#import "DeviceController.h"
#import "BTManager.h"

@interface ViewController ()

@property (weak, nonatomic) IBOutlet UITableView *table;
@property (strong, nonatomic) NSArray *devices;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [_activityIndicator startAnimating];
    [[BTManager sharedInstance] setDelegate:self];
    [[BTManager sharedInstance] start];
}

- (void) didUpdateState:(BOOL)active {
    if (active) [_activityIndicator startAnimating];
    else [_activityIndicator stopAnimating];
}

- (void) discoveredChanged:(NSMutableArray *)discovered {
    self.devices = discovered;
    [self.table reloadData];
}

- (void) connectedChanged:(NSMutableArray *)connected {
    [self.table reloadData];
}

- (void) errorOccured:(NSError *)error {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"BTLE" message:@"Error occured" delegate:nil
                                          cancelButtonTitle:@"Cancel" otherButtonTitles:nil];
    [alert show];
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.devices count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    CBPeripheral *device = [self.devices objectAtIndex:indexPath.row];
    
    static NSString *identifier = @"DeviceCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (!cell) cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:identifier];
    
    NSString *name = device.name;
    cell.textLabel.text = name;

    if (device.state == CBPeripheralStateConnected) {
        cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
    }
    else if (device.state == CBPeripheralStateConnecting) cell.accessoryType = UITableViewCellAccessoryNone;
    else if (device.state == CBPeripheralStateDisconnected) cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    return cell;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    
    CBPeripheral *device = [self.devices objectAtIndex:indexPath.row];
    [self performSegueWithIdentifier:@"device" sender:device];
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"device"]) {
        DeviceController *c = segue.destinationViewController;
        c.device = sender;
    }
}

@end
