//
//  BTManager.h
//  Tester
//
//  Created by Andrey Ogrenich on 29/07/14.
//  Copyright (c) 2014 Andrey Ogrenich. All rights reserved.
//

#import <Foundation/Foundation.h>

#define SHIELD_MAIN_SERVICE_UUID        @"FFE0"
#define SHIELD_CHAR_RX_UUID             @"FFE1"

#define SHIELD_NAME_REQUIRED_PREFIX     @"AnyFlite"


#define BT_ERRORS_DOMAIN @"com.ogrenich.shield:BTERRORS"
#define ERROR_CODE_BT_UNAVAILABLE 1
#define ERROR_CODE_COULD_NOT_CONNECT_TO_DEVICE 2

//---------------------------------------------------------------------------------------
#pragma mark - PROTOCOL DEFINES

// SETTING SHIT TO SHIELD
// heat
#define COMMAND_GET_HEAT_VALUE 0x65             // 101
#define COMMAND_SET_HEAT_VALUE_HEX 0x66         // 102
// mode
#define COMMAND_GET_MODE 0x67                   // 103
#define COMMAND_SET_MODE 0x68                   // 104

// NOTIFICATIONS FROM SHIELD
// mode notifications
#define NOTIFICATION_MODE_IS_MANUAL                  121
#define NOTIFICATION_MODE_IS_AUTO                    122


// battery/charging
//#define NOTIFICATION_BATTERY_UPDATED                 123
//#define NOTIFICATOON_IS_CHARGING_UPDATED             124


@protocol BTManagerDelegate;

@interface BTManager : NSObject

@property (weak, nonatomic) id<BTManagerDelegate> delegate;
@property (strong, nonatomic) NSMutableArray *discoveredShields;
@property (strong, nonatomic) Shield *connectedShield;

+ (BTManager *)sharedInstance;

- (void)scanForShieldsForSeconds:(NSInteger)seconds;
- (void)connectToShield:(Shield *)shield;
- (void)disconnectFromConnectedShield;

// setting and requesting values with conected shield
- (void)setHeat:(NSInteger)heat;
- (void)requestHeat;

- (void)setMode:(ShieldMode)mode;
- (void)requestMode;


// TESTING
- (void)writeToConecttedShield:(NSData *)data;

@end

@protocol BTManagerDelegate <NSObject>
@optional
- (void)btManagerUpdatedDiscoveredShields:(BTManager *)manager;
- (void)btManagerDidStartScanningForShields:(BTManager *)manager;
- (void)btManagerDidEndScanningForShields:(BTManager *)manager;
- (void)btManagerDidConnectToShield:(BTManager *)manager;
- (void)btManagerDidDisconnectFromShield:(BTManager *)manager;
- (void)btManager:(BTManager *)manager errorOccured:(NSError *)error;

// value request answers
- (void)shieldHeatIs:(NSInteger)heat;
- (void)shieldModeIs:(ShieldMode)mode;
@end

@interface CBPeripheral (Additions)
- (CBCharacteristic *)findCharacteristicForServiceUUID:(CBUUID *)serviceUUID characteristicUUID:(CBUUID *)charUUID;
@end
