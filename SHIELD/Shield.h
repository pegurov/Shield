//
//  Shield.h
//  SHIELD
//
//  Created by Pavel Gurov on 18/09/14.
//  Copyright (c) 2014 Andrey Ogrenich. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Shield : NSObject

@property (strong, nonatomic) CBPeripheral *peripheral;

- (BOOL)isEqualToShield:(Shield *)shield;

@end
