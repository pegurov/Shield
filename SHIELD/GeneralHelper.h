//
//  GeneralHelper.h
//  SHIELD
//
//  Created by Pavel Gurov on 19/08/14.
//  Copyright (c) 2014 Andrey Ogrenich. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

// SEGUE IDS
#define SEGUE_ID_DEVICE_DETAIL @"SEGUE_ID_DEVICE_DETAIL"


@interface GeneralHelper : NSObject

+ (void)showFrameOfView:(UIView *)view withColor:(UIColor *)color;

@end