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


// setting and requesting values with conected shield
- (void)setHeat:(NSInteger)heat
{
    
}

- (void)requestHeat
{
    
}

- (void)setMode:(ShieldMode)mode
{
    
}

- (void)requestMode
{
    
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
    for (CBCharacteristic *ch in service.characteristics) {
        [peripheral setNotifyValue:YES forCharacteristic:ch];
    }
    
    // notify delegate about the new connection
    Shield *shieldWeAreConnectingTo = nil;
    for (Shield *discoveredShield in self.discoveredShields) {
        if ([discoveredShield.peripheral isEqual:peripheral]) {
            shieldWeAreConnectingTo = discoveredShield;
            break;
        }
    }
    
    if (shieldWeAreConnectingTo) {
        
        // now we need to get the mode and heat value of the shield
        
        self.connectedShield = shieldWeAreConnectingTo;
        if ([self.delegate respondsToSelector:@selector(btManagerDidConnectToShield:)]) {
            [self.delegate btManagerDidConnectToShield:self];
        }
    }
}


// ------------------------------------------------------------------------------
#pragma mark - Notifications

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{

//    [[self delegate] btManager:self didReceiveData:characteristic.value];
    
//        NSString *dataString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
//        NSScanner *scanner = [NSScanner scannerWithString:dataString];
//        
//        NSCharacterSet *digitsSet = [NSCharacterSet decimalDigitCharacterSet];
//        NSCharacterSet *scanUpToSet = [[NSCharacterSet decimalDigitCharacterSet] invertedSet];
//        NSMutableArray *scannedStrings = [NSMutableArray array];
//        
//        while (!scanner.isAtEnd) {
//            
//            NSString *scannedString = @"";
//            [scanner scanUpToCharactersFromSet:scanUpToSet intoString:&scannedString];
//            [scannedStrings addObject:scannedString];
//            [scanner scanUpToCharactersFromSet:digitsSet intoString:nil];
//        }
//        
//        NSLog(@"%@", scannedStrings);
//        
//        if (scannedStrings.count == 2) {
//            
//            NSInteger commandByte = [scannedStrings[0] integerValue];
//            NSInteger valueByte = [scannedStrings[1] integerValue];
//            
//            //        if (commandByte == COMMAND_BATTERY_UPDATED) {
//            //            self.batteryLevel = valueByte;
//            //        }
//            //        else if (commandByte == COMMAND_IS_CHARGING_UPDATED) {
//            //            self.isCharging = (valueByte == 1) ? YES : NO;
//            //        }
//        }
//        
//        [self updateLabels];
}


// ------------------------------------------------------------------------------
#pragma mark - Reading

//- (void)readFromConnectedShield
//{
//    CBUUID *mainServiceUUID = [CBUUID UUIDWithString:SHIELD_MAIN_SERVICE_UUID];
//    CBUUID *txCharUUID = [CBUUID UUIDWithString:SHIELD_CHAR_TX_UUID];
//    
//    [self readValueFromPeripheral:self.connectedShield.peripheral serviceUUID:mainServiceUUID characteristicUUID:txCharUUID];
//}
//
//- (void)readValueFromPeripheral:(CBPeripheral *)peripheral
//                    serviceUUID:(CBUUID *)serviceUUID
//             characteristicUUID:(CBUUID *)characteristicUUID
//{
//    CBCharacteristic *foundCharcteristic = [peripheral findCharacteristicForServiceUUID:serviceUUID characteristicUUID:characteristicUUID];
//    if (foundCharcteristic) {
//        [peripheral readValueForCharacteristic:foundCharcteristic];
//    }
//    else {
//        NSLog(@"Could not read from characteristic with UUID %@ on peripheral %@", characteristicUUID, peripheral);
//    }
//}

// ------------------------------------------------------------------------------
#pragma mark - Writing

//- (void)writeToShield
//{
//    // we need to write 2 times
//    // first is command, then value
//
//    unsigned char actionCommand = COMMAND_SET_HEAT_VALUE_HEX;
//    unsigned char valueCommand = 0x64 * (1-self.sliderValue); // 0x64 is 100 in hex
//
//    [[BTManager sharedInstance] writeToConecttedShield:[NSMutableData dataWithBytes:&actionCommand length:sizeof(actionCommand)]];
//
//    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//        [[BTManager sharedInstance] writeToConecttedShield:[NSMutableData dataWithBytes:&valueCommand length:sizeof(valueCommand)]];
//    });
//
//}


- (void)setHeatLevelToConnectedShield:(NSInteger)heatLevel
{
    
}

- (void)writeToConecttedShield:(NSData *)data
{
// LOGGING
//    unsigned result = 0;
//    NSScanner *scanner = [NSScanner scannerWithString:[NSString stringWithFormat:@"%@", data]];
//    [scanner setScanLocation:1]; // bypass '<' character
//    [scanner scanHexInt:&result];
    
    NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    unsigned short len = [string length];
    NSMutableArray *arr = [NSMutableArray arrayWithCapacity:len];
    for (unsigned i = 0; i < len; ++i) {
        [arr addObject:[NSNumber numberWithUnsignedShort:[string characterAtIndex:i]]];
    }
    
    NSLog(@"writing to shield: %@", arr);
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

