//
//  NoAnimationSegue.m
//  SHIELD
//
//  Created by Pavel Gurov on 11/04/15.
//  Copyright (c) 2015 Andrey Ogrenich. All rights reserved.
//

#import "NoAnimationSegue.h"

@implementation NoAnimationSegue

- (void)perform {
    [[[self sourceViewController] navigationController] pushViewController:[self   destinationViewController] animated:NO];
}

@end
