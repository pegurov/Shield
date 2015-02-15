//
//  BTManager.m
//  Tester
//
//  Created by Andrey Ogrenich on 29/07/14.
//  Copyright (c) 2014 Andrey Ogrenich. All rights reserved.
//


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
            
            if ([self.delegate respondsToSelector:@selector(btManagerDidStartScanningForShields:)]) {
                [self.delegate btManagerDidStartScanningForShields:self];
            }
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
    
    if ([self.delegate respondsToSelector:@selector(btManagerDidEndScanningForShields:)]) {
        [self.delegate btManagerDidEndScanningForShields:self];
    }
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
        if ([self.delegate respondsToSelector:@selector(btManager:errorOccured:)]) {
            [self.delegate btManager:self errorOccured:error];
        }
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
        if ([self.delegate respondsToSelector:@selector(btManager:errorOccured:)]) {
            [self.delegate btManager:self errorOccured:error];
        }
    }
}

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral
      advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI
{
    if (![self.discoveredShields containsObject:peripheral]) {
        
        Shield *newDevice = [[Shield alloc] init];
        newDevice.peripheral = peripheral;
        [self.discoveredShields addObject:newDevice];
        if ([self.delegate respondsToSelector:@selector(btManagerUpdatedDiscoveredShields:)]) {
            [self.delegate btManagerUpdatedDiscoveredShields:self];
        }
    }
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    // we consider a device connected only ahen all
    // charachteristics for its MAIN SERVICE have been found
    
    [peripheral setDelegate:self];
    [peripheral discoverServices:nil];
}

- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    if ([self.delegate respondsToSelector:@selector(btManager:errorOccured:)]) {
        [self.delegate btManager:self errorOccured:error];
    }
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    NSLog(@"Disconnected from %@", peripheral.identifier.UUIDString);
    if ([self.delegate respondsToSelector:@selector(btManagerDidDisconnectFromShield:)]) {
        [self.delegate btManagerDidDisconnectFromShield:self];
    }
}


#pragma mark - CBPeripheralDelegate

- (void)peripheralDidUpdateRSSI:(CBPeripheral *)peripheral error:(NSError *)error
{
    NSLog(@"SHIELD %@ updated RSSI:%@", peripheral.identifier, peripheral.RSSI);
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
    for (CBService *service in peripheral.services)
    {
        if ([service.UUID.UUIDString isEqualToString:SHIELD_MAIN_SERVICE_UUID]) {
            [peripheral discoverCharacteristics:nil forService:service];
        }
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    // here we can consider the device connected, because we
    // only need characteristics for SHIELD_MAIN_SERVICE_UUID
    
    for (CBCharacteristic *ch in service.characteristics) {
        [peripheral setNotifyValue:YES forCharacteristic:ch];
    }
    
    // notify delegate about the new connection
    Shield *connectedShield = nil;
    for (Shield *discoveredShield in self.discoveredShields) {
        if ([discoveredShield.peripheral isEqual:peripheral]) {
            connectedShield = discoveredShield;
            break;
        }
    }
    
    if (connectedShield) {
        self.connectedShield = connectedShield;
        if ([self.delegate respondsToSelector:@selector(btManagerDidConnectToShield:)]) {
            [self.delegate btManagerDidConnectToShield:self];
        }
    }
}


// ------------------------------------------------------------------------------
#pragma mark - Notifications

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{

    [[self delegate] btManager:self didReceiveData:characteristic.value];
    
    
//    unsigned char data[20];
//
//    static unsigned char buf[512];
//    static int len = 0;
//    NSInteger data_len;
//
//    if (!error)
//    {
//        if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:SHIELD_CHAR_TX_UUID]])
//        {
//            data_len = characteristic.value.length;
//            [characteristic.value getBytes:data length:data_len];
//
//            if (data_len == 20)
//            {
//                memcpy(&buf[len], data, 20);
//                len += data_len;
//
//                if (len >= 64)
//                {
//                    if ([self.delegate respondsToSelector:@selector(btManager:didReceiveData:length:)]) {
//                        [[self delegate] btManager:self didReceiveData:buf length:len];
//                    }
//                    len = 0;
//                }
//            }
//            else if (data_len < 20)
//            {
//                memcpy(&buf[len], data, data_len);
//                len += data_len;
//
//                if ([self.delegate respondsToSelector:@selector(btManager:didReceiveData:length:)]) {
//                    
//                }
//                len = 0;
//            }
//        }
//    }
//    else
//    {
//        NSLog(@"updateValueForCharacteristic failed!");
//    }
}


// ------------------------------------------------------------------------------
#pragma mark - Reading

- (void)readFromConnectedShield
{
    CBUUID *mainServiceUUID = [CBUUID UUIDWithString:SHIELD_MAIN_SERVICE_UUID];
    CBUUID *txCharUUID = [CBUUID UUIDWithString:SHIELD_CHAR_TX_UUID];
    
    [self readValueFromPeripheral:self.connectedShield.peripheral serviceUUID:mainServiceUUID characteristicUUID:txCharUUID];
}

- (void)readValueFromPeripheral:(CBPeripheral *)peripheral
                    serviceUUID:(CBUUID *)serviceUUID
             characteristicUUID:(CBUUID *)characteristicUUID
{
    CBCharacteristic *foundCharcteristic = [peripheral findCharacteristicForServiceUUID:serviceUUID characteristicUUID:characteristicUUID];
    if (foundCharcteristic) {
        [peripheral readValueForCharacteristic:foundCharcteristic];
    }
    else {
        NSLog(@"Could not read from characteristic with UUID %@ on peripheral %@", characteristicUUID, peripheral);
    }
}

// ------------------------------------------------------------------------------
#pragma mark - Writing

- (void)setHeatLevelToConnectedShield:(NSInteger)heatLevel
{
    
}

- (void)writeToConecttedShield:(NSData *)data
{
// LOGGING
    unsigned result = 0;
    NSScanner *scanner = [NSScanner scannerWithString:[NSString stringWithFormat:@"%@", data]];
    [scanner setScanLocation:1]; // bypass '<' character
    [scanner scanHexInt:&result];
    NSLog(@"writing %u to shield", result);
// /LOGGING
    
    
    CBUUID *mainServiceUUID = [CBUUID UUIDWithString:SHIELD_MAIN_SERVICE_UUID];
    CBUUID *rxCharUUID = [CBUUID UUIDWithString:SHIELD_CHAR_RX_UUID];
    
    [self writeValueToPeripheral:self.connectedShield.peripheral serviceUUID:mainServiceUUID characteristicUUID:rxCharUUID data:data];
}

- (void)writeValueToPeripheral:(CBPeripheral *)peripheral
                   serviceUUID:(CBUUID *)serviceUUID
            characteristicUUID:(CBUUID *)characteristicUUID
                          data:(NSData *)data
{
    CBCharacteristic *foundCharcteristic = [peripheral findCharacteristicForServiceUUID:serviceUUID characteristicUUID:characteristicUUID];
    if (foundCharcteristic) {
        [peripheral writeValue:data forCharacteristic:foundCharcteristic type:CBCharacteristicWriteWithoutResponse];
    }
    else {
        NSLog(@"Could not read from characteristic with UUID %@ on peripheral %@", characteristicUUID, peripheral);
    }
}


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


@implementation CBPeripheral (Additions)

- (CBCharacteristic *)findCharacteristicForServiceUUID:(CBUUID *)serviceUUID characteristicUUID:(CBUUID *)charUUID
{
    CBService *foundService = nil;
    
    for (CBService *someService in self.services)
    {
        if ([serviceUUID isEqual:someService.UUID]) {
            foundService = someService;
            break;
        }
    }
    
    if (foundService) {
        
        for (CBCharacteristic *someCharachteristic in foundService.characteristics)
        {
            if ([charUUID isEqual:someCharachteristic.UUID]) {
                return someCharachteristic;
            }
        }
    }
    
    return nil;
}

@end

