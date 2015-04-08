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

// COMMANDS
// Commands that the phone sends to arduino
// setters
#define COMMAND_SET_HEAT 0x01 // 01
#define COMMAND_SET_MODE 0x02 // 02
// getters
#define COMMAND_GET_STATE 0x03 // 03

//// Commands that arduino sends to the phone
#define COMMAND_STATE_IS 0x65 // 101

#define AT_COMMAND_START 0x41 // 'A' AT commands start with AT+
#define AT_RESPONSE_START 0x4F // 'O' responses start with OK+

@protocol BTManagerDelegate;

@interface BTManager : NSObject

+ (BTManager *)sharedInstance;

@property (weak, nonatomic) id<BTManagerDelegate> delegate;
@property (strong, nonatomic) NSMutableArray *discoveredShields;
@property (strong, nonatomic) Shield *connectedShield;

- (void)scanForShieldsForSeconds:(NSInteger)seconds;
- (void)connectToShield:(Shield *)shield completionBlock:(void (^)(BOOL successful))completionBlock;
- (void)disconnectFromConnectedShield;

// setting and requesting values with conected shield
- (void)setHeat:(NSInteger)heat;
- (void)setMode:(ShieldMode)mode;
- (void)getStateWithCompletionBlock:(void (^)(BOOL successful))completionBlock;

// command must be shorter than 20 bytes
- (void)sendATCommandToHM11:(NSString *)command
                    timeout:(NSInteger)timeout
            completionBlock:(void (^)(BOOL successful, NSString *response))completionBlock;
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
