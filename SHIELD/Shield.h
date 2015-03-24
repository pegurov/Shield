//
//  Shield.h
//  SHIELD
//
//  Created by Pavel Gurov on 18/09/14.
//  Copyright (c) 2014 Andrey Ogrenich. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, ShieldMode) {
    ShieldModeManual,
    ShieldModeAuto
};

@interface Shield : NSObject

@property (strong, nonatomic) CBPeripheral *peripheral;
- (BOOL)isEqualToShield:(Shield *)object;

@property (nonatomic) NSInteger heat;
@property (nonatomic) ShieldMode mode;

@end
