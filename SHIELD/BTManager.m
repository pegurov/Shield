//
//  BTManager.m
//  Tester
//
//  Created by Andrey Ogrenich on 29/07/14.
//  Copyright (c) 2014 Andrey Ogrenich. All rights reserved.
//

#import "BTManager.h"

#define BLE_MAIN_SERVICE_UUID  @"713D0000-503E-4C75-BA94-3148F18D941E"


@interface BTManager ()

@property (nonatomic, strong) CBCentralManager *manager;

@property (nonatomic, strong) NSMutableArray *discovered;

@property (nonatomic, strong) CBPeripheral *connectedPeripheral;
@property (nonatomic, strong) CBCharacteristic *characteristic;

@end

@implementation BTManager

- (id)init
{
    self = [super init];
    if (self) {
        self.manager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
        self.discovered = [NSMutableArray array];
    }
    return self;
}

- (void)startScanning
{
    if (self.manager.state == CBCentralManagerStatePoweredOn) {

        [self.manager stopScan];
        [self.manager scanForPeripheralsWithServices:nil options:nil];
        [self.delegate didUpdateState:BTManagerStateIsLooking];
    }
}

- (void)stopScanning
{
    [self.manager stopScan];
    
    if (self.connectedPeripheral) {
        [self.manager cancelPeripheralConnection:self.connectedPeripheral];
    }

    self.discovered = [NSMutableArray new];
    
    [self.delegate didUpdateState:BTManagerStateIsDoingNothing];
}

- (void)connectToDevice:(CBPeripheral *)device
{
    [self.manager connectPeripheral:device options:nil];
}

#pragma mark - CBCentralManagerDelegate

- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    if (central.state == CBCentralManagerStatePoweredOn) {
        [self startScanning];
    }
    else {
        [self.delegate errorOccured:[NSError errorWithDomain:@"BTLE" code:1 userInfo:nil]];
    }
}

- (void)centralManager:(CBCentralManager *)central didRetrievePeripherals:(NSArray *)peripherals
{
    for (CBPeripheral *peripheral in peripherals) {
        
        if (![self.discovered containsObject:peripheral]) {
            [self.discovered addObject:peripheral];
            [self.delegate discoveredChanged:self.discovered];
        }
    }
}

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral
      advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI
{
    if (![self.discovered containsObject:peripheral]) {
        [self.discovered addObject:peripheral];
        [self.delegate discoveredChanged:self.discovered];
    }
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    [peripheral setDelegate:self];
    [peripheral discoverServices:nil];
}

- (void) centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral
                  error:(NSError *)error
{
    NSLog(@"Failed to connect to %@", peripheral.identifier.UUIDString);
}

- (void) centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral
                  error:(NSError *)error
{
    NSLog(@"Disconnected from %@", peripheral.identifier.UUIDString);
    if (error) [self.delegate errorOccured:error];
}


#pragma mark - CBPeripheralDelegate

- (void)peripheralDidUpdateRSSI:(CBPeripheral *)peripheral error:(NSError *)error
{
    NSLog(@"");
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
    for (CBService *service in peripheral.services)
    {
//        if ([service.UUID.UUIDString isEqualToString:BLE_MAIN_SERVICE_UUID]) {
            [peripheral discoverCharacteristics:nil forService:service];
//        }
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service
              error:(NSError *)error
{
    NSLog(@"Discovered characteristics of service %@ of device %@:", service.UUID.UUIDString, peripheral.identifier.UUIDString);
    

//<CBCharacteristic: 0x170280230 UUID = 713D0003-503E-4C75-BA94-3148F18D941E, Value = (null), Properties = 0x4, Notifying = NO, Broadcasting = NO>,
//<CBCharacteristic: 0x170280410 UUID = 713D0002-503E-4C75-BA94-3148F18D941E, Value = (null), Properties = 0x10, Notifying = NO, Broadcasting = NO>

    
    for (CBCharacteristic *ch in service.characteristics) {
        NSLog(@"Characteristic %@", ch.UUID.UUIDString);

//        if ([ch.UUID.UUIDString isEqualToString:kCharUUID]) {
//            self.characteristic = ch;
//            [peripheral setNotifyValue:YES forCharacteristic:ch];
//        }
    }
}

- (void) peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic
              error:(NSError *)error
{
    NSLog(@"Characteristic %@ updated it's value", characteristic.UUID.UUIDString);
    if (_onNewData) _onNewData(characteristic.value, error);
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
