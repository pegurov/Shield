//
//  CommonTableViewCell.m
//  Marathon
//
//  Created by Pavel Gurov on 29/01/14.
//  Copyright (c) 2014 BBApps. All rights reserved.
//

#import "CommonTableViewCell.h"

@implementation CommonTableViewCell

+ (NSString *)cellIdentifier
{
    return [self nibName];
}

+ (NSString *)nibName
{
    return [NSString stringWithFormat:@"%@", [self class]];
}

- (NSString *)reuseIdentifier
{
    return [self.class cellIdentifier];
}

+ (CGFloat)cellHeight
{
    return 100;
}

@end