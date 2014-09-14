//
//  BTManager.h
//  Tester
//
//  Created by Andrey Ogrenich on 29/07/14.
//  Copyright (c) 2014 Andrey Ogrenich. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, BTManagerState) {
    BTManagerStateIsDoingNothing = 0,
    BTManagerStateIsLooking
};

typedef void (^bDataErrorBlock)(NSData *, NSError *);
@protocol BTManagerDelegate;

@interface BTManager : NSObject <CBCentralManagerDelegate, CBPeripheralDelegate>

@property (nonatomic, assign) id<BTManagerDelegate> delegate;
@property (nonatomic, copy) bDataErrorBlock onNewData;

+ (BTManager *) sharedInstance;

- (void)startScanning;
- (void)connectToDevice:(CBPeripheral *)device;

//- (void)writeValue:(NSData *)data;

@end

@protocol BTManagerDelegate <NSObject>

@required
- (void)didUpdateState:(BTManagerState)state;
- (void)discoveredChanged:(NSMutableArray *)discovered;
- (void)connectedChanged:(CBPeripheral *)connected;
- (void)errorOccured:(NSError *)error;
@end