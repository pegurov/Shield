//
//  Shield.h
//  SHIELD
//
//  Created by Pavel Gurov on 18/09/14.
//  Copyright (c) 2014 Andrey Ogrenich. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol ShieldDelegate;

typedef NS_ENUM(NSUInteger, ShieldMode) {
    ShieldModeManual,
    ShieldModeAuto
};

@interface Shield : NSObject

@property (weak, nonatomic) id<ShieldDelegate> delegate;
@property (strong, nonatomic) CBPeripheral *peripheral;
@property (nonatomic) NSInteger heat;
@property (nonatomic) ShieldMode mode;
@property (strong, nonatomic) NSNumber *temperature;
@property (nonatomic) BOOL isCharging;

- (BOOL)isEqualToShield:(Shield *)object;

@end

@protocol ShieldDelegate <NSObject>
@optional
- (void)shieldDidUpdateHeat:(Shield *)shield;
- (void)shieldDidUpdateMode:(Shield *)shield;
- (void)shieldDidUpdateTemperature:(Shield *)shield;
- (void)shieldDidUpdateIsCharging:(Shield *)shield;
@end

