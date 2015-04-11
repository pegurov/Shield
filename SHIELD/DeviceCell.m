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
@property (weak, nonatomic) IBOutlet UILabel *labelStatus;

@property (strong, nonatomic) Shield *device;
@end

@implementation DeviceCell

- (void)setDevice:(Shield *)device
{
    _device = device;

    [self.labelName setTextColor:[UIColor blackColor]];
    [self.labelName setText:device.peripheral.name];
    
    if (device.peripheral.state == CBPeripheralStateConnected) {
        // CONNECTED
        self.selectionStyle = UITableViewCellSelectionStyleDefault;
        if (device.password && !device.passwordValidated) {
            [self.labelStatus setText:@"connected, need passcode"];
        }
        else {
            [self.labelStatus setText:@"paired"];
        }
    }
    else if (device.peripheral.state == CBPeripheralStateConnecting) {
        // CONNECTING
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        [self.labelStatus setText:@"pairing"];
    }
    else {
        // CONNECTABLE
        self.selectionStyle = UITableViewCellSelectionStyleDefault;
        [self.labelStatus setText:@"connectable"];
    }
}

@end
