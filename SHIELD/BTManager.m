//
//  BTManager.m
//  Tester
//
//  Created by Andrey Ogrenich on 29/07/14.
//  Copyright (c) 2014 Andrey Ogrenich. All rights reserved.
//

//@property (nonatomic, strong) NSMutableArray *discovered;
//@property (nonatomic, strong) CBPeripheral *connectedPeripheral;
//@property (nonatomic, strong) CBCharacteristic *characteristic;


#import "BTManager.h"


@interface BTManager () <CBCentralManagerDelegate, CBPeripheralDelegate>
@property (nonatomic, strong) CBCentralManager *centralBTManager;

// flags
@property (nonatomic) BOOL isScanning;
@end

@implementation BTManager

- (id)init
{
    self = [super init];
    if (self) {
        self.centralBTManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
        self.discoveredShields = [NSMutableArray array];
    }
    return self;
}

//----------------------------------------------------------------------------------------
#pragma mark - public API

- (void)scanForShieldsForSeconds:(NSInteger)seconds
{
    if (self.centralBTManager.state == CBCentralManagerStatePoweredOn) {
        
        if (!self.isScanning) {
            
            [self.delegate btManagerDidStartScanningForShields:self];
            self.isScanning = YES;
            [self.centralBTManager stopScan];
            CBUUID *shieldMainServiceUUID = [CBUUID UUIDWithString:SHIELD_MAIN_SERVICE_UUID];
            [self.centralBTManager scanForPeripheralsWithServices:@[shieldMainServiceUUID] options:nil];
            
            dispatch_time_t delay = dispatch_time(DISPATCH_TIME_NOW, seconds * NSEC_PER_SEC);
            dispatch_after(delay, dispatch_get_main_queue(), ^(void){
                [self stopScanningForShields];
            });
        }
    }
    else {
        
        [self stopScanningForShields];
    }
}

- (void)stopScanningForShields
{
    self.isScanning = NO;
    [self.centralBTManager stopScan];
    [self disconnectFromConnectedShield];
    
    [self.delegate btManagerDidEndScanningForShields:self];
}

- (void)connectToShield:(Shield *)shield
{
    if (shield.peripheral.state == CBPeripheralStateDisconnected) {
        
        [self.centralBTManager connectPeripheral:shield.peripheral options:nil];
    }
    else {
        
        NSError *error = [NSError errorWithDomain:BT_ERRORS_DOMAIN
                                             code:ERROR_CODE_COULD_NOT_CONNECT_TO_DEVICE
                                         userInfo:nil];
        [self.delegate btManager:self errorOccured:error];
    }
}

- (void)disconnectFromConnectedShield
{
    if (self.connectedShield) {
        
        [self.centralBTManager cancelPeripheralConnection:self.connectedShield.peripheral];
    }
}


//----------------------------------------------------------------------------------------
#pragma mark - CBCentralManagerDelegate

- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    if (central.state == CBCentralManagerStatePoweredOn) {
        
        [self scanForShieldsForSeconds:3];
    }
    else {
        
        NSError *error = [NSError errorWithDomain:BT_ERRORS_DOMAIN
                                             code:ERROR_CODE_BT_UNAVAILABLE
                                         userInfo:nil];
        [self.delegate btManager:self errorOccured:error];
    }
}

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral
      advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI
{
    if (![self.discoveredShields containsObject:peripheral] && [peripheral.name hasPrefix:SHIELD_NAME_REQUIRED_PREFIX]) {
        
        Shield *newDevice = [[Shield alloc] init];
        newDevice.peripheral = peripheral;
        [self.discoveredShields addObject:newDevice];
        [self.delegate btManagerUpdatedDiscoveredShields:self];
    }
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    // we consider a device connected only ahen all
    // charachteristics for its services have been found
    
    [peripheral setDelegate:self];
    [peripheral discoverServices:nil];
}

- (void) centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    [self.delegate btManager:self errorOccured:error];
}

- (void) centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    NSLog(@"Disconnected from %@", peripheral.identifier.UUIDString);
    if (error) [self.delegate btManager:self errorOccured:error];
}


#pragma mark - CBPeripheralDelegate

- (void)peripheralDidUpdateRSSI:(CBPeripheral *)peripheral error:(NSError *)error
{
//    NSLog(@"SHIELD %@ updated RSSI:%@", peripheral.identifier, peripheral.RSSI);
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
//    for (CBService *service in peripheral.services)
//    {
//        if ([service.UUID.UUIDString isEqualToString:BLE_MAIN_SERVICE_UUID]) {
//            [peripheral discoverCharacteristics:nil forService:service];
//        }
//    }
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
//    NSLog(@"Discovered characteristics of service %@ of device %@:", service.UUID.UUIDString, peripheral.identifier.UUIDString);
    

//<CBCharacteristic: 0x170280230 UUID = 713D0003-503E-4C75-BA94-3148F18D941E, Value = (null), Properties = 0x4, Notifying = NO, Broadcasting = NO>,
//<CBCharacteristic: 0x170280410 UUID = 713D0002-503E-4C75-BA94-3148F18D941E, Value = (null), Properties = 0x10, Notifying = NO, Broadcasting = NO>

    
//    for (CBCharacteristic *ch in service.characteristics) {
//        NSLog(@"Characteristic %@", ch.UUID.UUIDString);

//        if ([ch.UUID.UUIDString isEqualToString:kCharUUID]) {
//            self.characteristic = ch;
//            [peripheral setNotifyValue:YES forCharacteristic:ch];
//        }
//    }
}

- (void) peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic
              error:(NSError *)error
{
//    NSLog(@"Characteristic %@ updated it's value", characteristic.UUID.UUIDString);
//    if (_onNewData) _onNewData(characteristic.value, error);
}

//- (void) writeValue:(NSData *)data
//{
//    [self.connectedPeripheral writeValue:data forCharacteristic:_characteristic type:CBCharacteristicWriteWithoutResponse];
//}

#pragma mark - Singleton

+ (BTManager *) sharedInstance
{
    static BTManager *__instance = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        __instance = [[BTManager alloc] init];
    });
    return __instance;
}

@end
