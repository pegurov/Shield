//
//  Shield.m
//  SHIELD
//
//  Created by Pavel Gurov on 18/09/14.
//  Copyright (c) 2014 Andrey Ogrenich. All rights reserved.
//

#import "Shield.h"

@implementation Shield

- (void)setHeat:(NSInteger)heat
{
    if (_heat != heat) {
        _heat = heat;
        if ([self.delegate respondsToSelector:@selector(shieldDidUpdateHeat:)]) {
            [self.delegate shieldDidUpdateHeat:self];
        }
    }
}

- (void)setMode:(ShieldMode)mode
{
    if (_mode != mode) {
        _mode = mode;
        if ([self.delegate respondsToSelector:@selector(shieldDidUpdateMode:)]) {
            [self.delegate shieldDidUpdateMode:self];
        }
    }
}

- (void)setTemperature:(NSNumber *)temperature
{
    if (_temperature != temperature) {
        _temperature = temperature;
        if ([self.delegate respondsToSelector:@selector(shieldDidUpdateIsCharging:)]) {
            [self.delegate shieldDidUpdateIsCharging:self];
        }
    }
}

- (void)setIsCharging:(BOOL)isCharging
{
    _isCharging = isCharging;
    if ([self.delegate respondsToSelector:@selector(shieldDidUpdateTemperature:)]) {
        [self.delegate shieldDidUpdateTemperature:self];
    }
}

- (BOOL)isEqual:(id)object
{
    if ([object isKindOfClass:[Shield class]]) {
        return [self isEqualToShield:object];
    }
    return NO;
}

- (BOOL)isEqualToShield:(Shield *)object
{
    return [self.peripheral isEqual:object.peripheral];
}

@end
