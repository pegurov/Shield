//
//  Shield.m
//  SHIELD
//
//  Created by Pavel Gurov on 18/09/14.
//  Copyright (c) 2014 Andrey Ogrenich. All rights reserved.
//

#import "Shield.h"

@implementation Shield

- (BOOL)isEqual:(id)object
{
    if (![object isKindOfClass:[Shield class]]) {
        return NO;
    }
    
    return [self isEqualToShield:object];
}

- (BOOL)isEqualToShield:(Shield *)shield
{
    return [self.peripheral isEqual:shield.peripheral];
}

@end
