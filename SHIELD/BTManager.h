//
//  BTManager.h
//  Tester
//
//  Created by Andrey Ogrenich on 29/07/14.
//  Copyright (c) 2014 Andrey Ogrenich. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>

typedef void (^bDataErrorBlock)(NSData *, NSError *);

@protocol BTManagerDelegate <NSObject>

@required
- (void) didUpdateState:(BOOL)active;
- (void) discoveredChanged:(NSMutableArray *)discovered;
- (void) connectedChanged:(NSMutableArray *)connected;

- (void) errorOccured:(NSError *)error;

@end

@interface BTManager : NSObject <CBCentralManagerDelegate, CBPeripheralDelegate>

@property (nonatomic, assign) id<BTManagerDelegate> delegate;
@property (nonatomic, copy) bDataErrorBlock onNewData;

+ (BTManager *) sharedInstance;

- (void) start;
- (void) stop;
- (void) writeValue:(NSData *)data;

@end
