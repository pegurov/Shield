//
//  GeneralHelper.m
//  SHIELD
//
//  Created by Pavel Gurov on 19/08/14.
//  Copyright (c) 2014 Andrey Ogrenich. All rights reserved.
//

#import "GeneralHelper.h"

@implementation GeneralHelper

+ (void)showFrameOfView:(UIView *)view withColor:(UIColor *)color
{
    view.layer.borderColor = [color CGColor];
    view.layer.borderWidth = 1;
}

@end