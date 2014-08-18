//
//  DeviceController.m
//  Tester
//
//  Created by Andrey Ogrenich on 29/07/14.
//  Copyright (c) 2014 Andrey Ogrenich. All rights reserved.
//

#import "DeviceController.h"
#import <CoreBluetooth/CoreBluetooth.h>
#import "BTManager.h"

@interface DeviceController ()

@end

@implementation DeviceController {
    UInt16 min, max;
}

static NSString *identifier = @"DeviceAxisCell";

- (void)viewDidLoad {
    [super viewDidLoad];
    UInt8 buf[1] = {0x01};
    NSData *data = [[NSData alloc] initWithBytes:buf length:1];
    [[BTManager sharedInstance] writeValue:data];
}

@end
