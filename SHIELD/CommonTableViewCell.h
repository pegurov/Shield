//
//  CommonTableViewCell.h
//  Marathon
//
//  Created by Pavel Gurov on 29/01/14.
//  Copyright (c) 2014 BBApps. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CommonTableViewCell : UITableViewCell

@property (nonatomic) CGFloat cellHeight;

+ (NSString *)nibName;
+ (NSString *)cellIdentifier;
+ (CGFloat)cellHeight;

@end