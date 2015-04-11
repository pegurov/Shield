//
//  PairedShieldConnectingViewController.h
//  SHIELD
//
//  Created by Pavel Gurov on 12/04/15.
//  Copyright (c) 2015 Andrey Ogrenich. All rights reserved.
//

#import "CommonViewController.h"

@protocol PairedShieldVCDelegate <NSObject>
- (void)didFinish;
@end

@interface PairedShieldConnectingViewController : CommonViewController

@property (weak, nonatomic) id<PairedShieldVCDelegate> delegate;
@end
