//
//  GeneralHelper.h
//  SHIELD
//
//  Created by Pavel Gurov on 19/08/14.
//  Copyright (c) 2014 Andrey Ogrenich. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

// DEFAULTS
#define DEF_KEY_PAIRED_SHIELD_UUID @"DEF_KEY_PAIRED_SHIELD_UUID"

// SEGUE IDS
#define SEGUE_ID_DEVICE_DETAIL @"SEGUE_ID_DEVICE_DETAIL"
#define SEGUE_ID_DEVICE_DETAIL_NO_ANIMATION @"SEGUE_ID_DEVICE_DETAIL_NO_ANIMATION"

@interface GeneralHelper : NSObject

+ (void)showFrameOfView:(UIView *)view withColor:(UIColor *)color;

@end