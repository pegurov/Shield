//
//  DeviceController.h
//  Tester
//
//  Created by Andrey Ogrenich on 29/07/14.
//  Copyright (c) 2014 Andrey Ogrenich. All rights reserved.
//

#import <UIKit/UIKit.h>

@class CBPeripheral;

@interface DeviceController : UIViewController

@property (nonatomic, strong) CBPeripheral *device;

@end
