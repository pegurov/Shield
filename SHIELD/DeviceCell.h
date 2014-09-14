//
//  DeviceCell.h
//  SHIELD
//
//  Created by Pavel Gurov on 15/09/14.
//  Copyright (c) 2014 Andrey Ogrenich. All rights reserved.
//

#import "CommonTableViewCell.h"

@interface DeviceCell : CommonTableViewCell

@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
- (void)setDevice:(CBPeripheral *)device;

@end