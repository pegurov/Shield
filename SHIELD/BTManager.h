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

// Commands that the phone sends to arduino are in range [101..109]
#define COMMAND_SET_HEAT 0x65 // 101
#define COMMAND_GET_HEAT 0x66 // 102
// mode
#define COMMAND_SET_MODE 0x67 // 103
#define COMMAND_GET_MODE 0x68 // 104
// battery level and chargin' indication
#define COMMAND_GET_IS_CHARGING 0x69 // 105
#define COMMAND_GET_BATTERY_LEVEL 0x6A // 106

// Commands that arduino sends to the phone are in range [111..120]
// heat level
#define COMMAND_HEAT_IS 111 // Sending back current heat level
// mode
#define COMMAND_MODE_IS 112 // Sending back current mode
// battery level and chargin'
#define COMMAND_IS_CHARGING 113 // Sending back charging status
#define COMMAND_BATTERY_LEVEL_IS 114 // Sending back battery level

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
@end

@protocol BTManagerDelegate <NSObject>
@optional
- (void)btManagerConnectedShieldUpdated:(BTManager *)manager;
- (void)btManagerUpdatedDiscoveredShields:(BTManager *)manager;
- (void)btManagerDidStartScanningForShields:(BTManager *)manager;
- (void)btManagerDidEndScanningForShields:(BTManager *)manager;
- (void)btManagerDidDisconnectFromShield:(BTManager *)manager;
- (void)btManager:(BTManager *)manager errorOccured:(NSError *)error;
@end

@interface CBPeripheral (Additions)
- (CBCharacteristic *)findCharacteristicForServiceUUID:(CBUUID *)serviceUUID characteristicUUID:(CBUUID *)charUUID;
@end
