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
