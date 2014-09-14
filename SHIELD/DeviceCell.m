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
@property (strong, nonatomic) CBPeripheral *device;
@end

@implementation DeviceCell

- (void)setDevice:(CBPeripheral *)device
{
    _device = device;
    [self.labelName setText:device.name];
}

@end
