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

#define BT_ERRORS_DOMAIN @"com.ogrenich.shield:BTERRORS"
#define ERROR_CODE_BT_UNAVAILABLE 1
#define ERROR_CODE_COULD_NOT_CONNECT_TO_DEVICE 2

//---------------------------------------------------------------------------------------
#pragma mark - API DEFINES

#define PROTOCOL_VERSION_HEX 0x01
#define PROTOCOL_VERSION 1

/* 
 Protocol explanation
 arduino and the phone exchange transmittions as a series of bytes
 one transmittion might include several messages
 
 every message consists of:
 1st byte = message length
 2nd byte = protocol version
 3rd byte = command byte
 next bytes = value bytes  */


// COMMANDS
// Commands that the phone sends to arduino
#define COMMAND_SET_HEAT 0x01 // 01
#define COMMAND_GET_HEAT 0x02 // 02
// mode
#define COMMAND_SET_MODE 0x03 // 03
#define COMMAND_GET_MODE 0x04 // 04
// battery level and chargin' indication
#define COMMAND_GET_IS_CHARGING 0x05 // 05
#define COMMAND_GET_BATTERY_LEVEL 0x06 // 06
// temperature
#define COMMAND_GET_TEMPERATURE 0x07 // 07

// Commands that arduino sends to the phone
// heat level
#define COMMAND_HEAT_IS 101
// mode
#define COMMAND_MODE_IS 102
// battery level and chargin'
#define COMMAND_IS_CHARGING 103
#define COMMAND_BATTERY_LEVEL_IS 104
// temperature
#define COMMAND_TEMPERATURE_IS 105
//---------------------------------------------------------------------------------------

@protocol BTManagerDelegate;

@interface BTManager : NSObject

@property (weak, nonatomic) id<BTManagerDelegate> delegate;
@property (strong, nonatomic) NSMutableArray *discoveredShields;
@property (strong, nonatomic) Shield *connectedShield;

+ (BTManager *)sharedInstance;

- (void)scanForShieldsForSeconds:(NSInteger)seconds;
- (void)connectToShield:(Shield *)shield completionBlock:(void (^)(Shield *connectedShield))completionBlock;
- (void)disconnectFromConnectedShield;

// setting and requesting values with conected shield
- (void)setHeat:(NSInteger)heat;
- (void)getHeatWithCompletionBlock:(void (^)(Shield *shield))completionBlock;

- (void)setMode:(ShieldMode)mode;
- (void)getModeWithCompletionBlock:(void (^)(Shield *shield))completionBlock;

- (void)getTemperatureWithCompletionBlock:(void (^)(Shield *shield))completionBlock;
@end

@protocol BTManagerDelegate <NSObject>
@optional
- (void)btManagerUpdatedDiscoveredShields:(BTManager *)manager;
- (void)btManagerDidStartScanningForShields:(BTManager *)manager;
- (void)btManagerDidEndScanningForShields:(BTManager *)manager;
- (void)btManagerDidDisconnectFromShield:(BTManager *)manager;
- (void)btManager:(BTManager *)manager errorOccured:(NSError *)error;
@end

@interface CBPeripheral (Additions)
- (CBCharacteristic *)findCharacteristicForServiceUUID:(CBUUID *)serviceUUID characteristicUUID:(CBUUID *)charUUID;
@end
