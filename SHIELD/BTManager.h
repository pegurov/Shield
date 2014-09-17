//
//  BTManager.h
//  Tester
//
//  Created by Andrey Ogrenich on 29/07/14.
//  Copyright (c) 2014 Andrey Ogrenich. All rights reserved.
//

#import <Foundation/Foundation.h>

//typedef NS_ENUM(NSInteger, BTManagerState) {
//    BTManagerStateIsDoingNothing = 0,
//    BTManagerStateIsLooking
//};
//typedef void (^bDataErrorBlock)(NSData *, NSError *);

//@property (nonatomic, copy) bDataErrorBlock onNewData;
//- (void)writeValue:(NSData *)data;

//- (void)didUpdateState:(BTManagerState)state;
//- (void)discoveredChanged:(NSMutableArray *)discovered;
//- (void)connectedChanged:(CBPeripheral *)connected;


#define SHIELD_MAIN_SERVICE_UUID        @"713D0000-503E-4C75-BA94-3148F18D941E"
#define SHIELD_NAME_REQUIRED_PREFIX     @"SHIELD"

#define BT_ERRORS_DOMAIN @"com.ogrenich.shield:BTERRORS"
#define ERROR_CODE_BT_UNAVAILABLE 1
#define ERROR_CODE_COULD_NOT_CONNECT_TO_DEVICE 2


@protocol BTManagerDelegate;

@interface BTManager : NSObject

@property (nonatomic, assign) id<BTManagerDelegate> delegate;
@property (strong, nonatomic) NSMutableArray *discoveredShields;
@property (strong, nonatomic) Shield *connectedShield;

+ (BTManager *)sharedInstance;

- (void)scanForShieldsForSeconds:(NSInteger)seconds;
- (void)connectToShield:(Shield *)shield;
- (void)disconnectFromConnectedShield;

@end

@protocol BTManagerDelegate <NSObject>

@required
- (void)btManagerUpdatedDiscoveredShields:(BTManager *)manager;
- (void)btManagerDidStartScanningForShields:(BTManager *)manager;
- (void)btManagerDidEndScanningForShields:(BTManager *)manager;
- (void)btManagerDidConnectToShield:(BTManager *)manager;
- (void)btManager:(BTManager *)manager errorOccured:(NSError *)error;
@end
