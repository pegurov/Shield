//
//  BTManager.h
//  Tester
//
//  Created by Andrey Ogrenich on 29/07/14.
//  Copyright (c) 2014 Andrey Ogrenich. All rights reserved.
//

#import <Foundation/Foundation.h>


#define SHIELD_MAIN_SERVICE_UUID        @"FFE0"

// this was in RBL Shield
#define SHIELD_CHAR_TX_UUID             @"713D0002-503E-4C75-BA94-3148F18D941E"

#warning - REPLACE THE NAME OF RX CHAR HERE for HMSoft
#define SHIELD_CHAR_RX_UUID             @"FFE1"


#define SHIELD_NAME_REQUIRED_PREFIX     @"AnyFlite"

#define BT_ERRORS_DOMAIN @"com.ogrenich.shield:BTERRORS"
#define ERROR_CODE_BT_UNAVAILABLE 1
#define ERROR_CODE_COULD_NOT_CONNECT_TO_DEVICE 2

// PROTOCOL DEFINES
#define COMMAND_BATTERY_UPDATED 102
#define COMMAND_IS_CHARGING_UPDATED 103

@protocol BTManagerDelegate;

@interface BTManager : NSObject

@property (nonatomic, assign) id<BTManagerDelegate> delegate;
@property (strong, nonatomic) NSMutableArray *discoveredShields;
@property (strong, nonatomic) Shield *connectedShield;

+ (BTManager *)sharedInstance;

- (void)scanForShieldsForSeconds:(NSInteger)seconds;
- (void)connectToShield:(Shield *)shield;
- (void)disconnectFromConnectedShield;

- (void)readFromConnectedShield;
- (void)writeToConecttedShield:(NSData *)data;
- (void)setHeatLevelToConnectedShield:(NSInteger)heatLevel; // 0 to 100

@end

@protocol BTManagerDelegate <NSObject>
@optional
- (void)btManagerUpdatedDiscoveredShields:(BTManager *)manager;
- (void)btManagerDidStartScanningForShields:(BTManager *)manager;
- (void)btManagerDidEndScanningForShields:(BTManager *)manager;
- (void)btManagerDidConnectToShield:(BTManager *)manager;
- (void)btManager:(BTManager *)manager errorOccured:(NSError *)error;
- (void)btManager:(BTManager *)manager didReceiveData:(NSData *)data;
@end


@interface CBPeripheral (Additions)
- (CBCharacteristic *)findCharacteristicForServiceUUID:(CBUUID *)serviceUUID characteristicUUID:(CBUUID *)charUUID;
@end


