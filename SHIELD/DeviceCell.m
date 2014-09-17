//
//  DeviceCell.m
//  SHIELD
//
//  Created by Pavel Gurov on 15/09/14.
//  Copyright (c) 2014 Andrey Ogrenich. All rights reserved.
//

#import "DeviceCell.h"

@interface DeviceCell()
@property (weak, nonatomic) IBOutlet UILabel *labelName;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;

@property (strong, nonatomic) Shield *device;
@end

@implementation DeviceCell

- (void)setDevice:(Shield *)device
{
    _device = device;

    [self.activityIndicator stopAnimating];
    [self.labelName setTextColor:[UIColor blackColor]];
    
    if (device.peripheral.state == CBPeripheralStateConnected) {

        self.selectionStyle = UITableViewCellSelectionStyleNone;
        [self.labelName setTextColor:[UIColor lightGrayColor]];
        [self.activityIndicator stopAnimating];
    }
    if (device.peripheral.state == CBPeripheralStateConnecting) {
        
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        [self.labelName setTextColor:[UIColor lightGrayColor]];
        [self.activityIndicator startAnimating];
    }
    else { // DISCONNECTED
        
        self.selectionStyle = UITableViewCellSelectionStyleDefault;
    }

    [self.labelName setText:device.peripheral.name];
}

@end
