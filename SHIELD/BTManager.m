//
//  BTManager.m
//  Tester
//
//  Created by Andrey Ogrenich on 29/07/14.
//  Copyright (c) 2014 Andrey Ogrenich. All rights reserved.
//

#import "BTManager.h"

#define kCharUUID   @"713D0003-503E-4C75-BA94-3148F18D941E"

@interface BTManager ()

@property (nonatomic, strong) CBCentralManager *manager;

@property (nonatomic, strong) NSMutableArray *discovered;
@property (nonatomic, strong) NSMutableArray *connected;
@property (nonatomic, strong) CBPeripheral *peripheral;
@property (nonatomic, strong) CBCharacteristic *characteristic;

@end

@implementation BTManager

- (id) init {
    self = [super init];
    if (self) {
        self.manager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
        self.discovered = [NSMutableArray new];
        self.connected = [NSMutableArray new];
    }
    return self;
}

- (void) start {
    if (_manager.state == CBCentralManagerStatePoweredOn) {
        [self.manager scanForPeripheralsWithServices:nil options:nil];
    }
    [self.delegate didUpdateState:YES];
}


- (void) stop {
    [self.manager stopScan];
    for (CBPeripheral *ph in _connected) [_manager cancelPeripheralConnection:ph];
    [self.delegate didUpdateState:NO];
    _discovered = [NSMutableArray new];
    _connected = [NSMutableArray new];
}



#pragma mark - CBCentralManagerDelegate

- (void) centralManagerDidUpdateState:(CBCentralManager *)central {
    if (central.state == CBCentralManagerStatePoweredOn) [central scanForPeripheralsWithServices:nil options:nil];
    else {
        [_delegate errorOccured:[NSError errorWithDomain:@"BTLE" code:1 userInfo:nil]];
    }
}

- (void) centralManager:(CBCentralManager *)central didRetrievePeripherals:(NSArray *)peripherals {
    for (CBPeripheral *peripheral in peripherals) {
        NSLog(@"Connecting to %@", peripheral.identifier.UUIDString);
        if (![_discovered containsObject:peripheral]) {
            [_discovered addObject:peripheral];
            [_delegate discoveredChanged:_discovered];
        }
        [_manager connectPeripheral:peripheral options:nil];
    }
}

- (void) centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral
      advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI {
    if (![_discovered containsObject:peripheral]) {
        [_discovered addObject:peripheral];
        [_delegate discoveredChanged:_discovered];
    }
     if ([peripheral.name hasPrefix:@"BLE"]) {
        self.peripheral = peripheral;
        NSLog(@"Connecting to %@", peripheral.identifier.UUIDString);
        [_manager connectPeripheral:peripheral options:nil];
    }
}

- (void) centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
    NSLog(@"Connected to %@", peripheral.identifier.UUIDString);
    [peripheral setDelegate:self];
    [_connected addObject:peripheral];
    [_delegate connectedChanged:_connected];
   
    [peripheral discoverServices:nil];
}

- (void) centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral
                  error:(NSError *)error {
    NSLog(@"Failed to connect to %@", peripheral.identifier.UUIDString);
    // show error
}

- (void) centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral
                  error:(NSError *)error {
    NSLog(@"Disconnected from %@", peripheral.identifier.UUIDString);
    if (error) [_delegate errorOccured:error];
}



#pragma mark - CBPeripheralDelegate

- (void) peripheralDidUpdateRSSI:(CBPeripheral *)peripheral error:(NSError *)error {
    // signal level changed
}

- (void) peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error {
    NSLog(@"Discovered services of %@:", peripheral.identifier.UUIDString);
    for (CBService *service in peripheral.services) {
        NSLog(@"Service %@", service.UUID.UUIDString);
        [peripheral discoverCharacteristics:nil forService:service];
    }
}

- (void) peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service
              error:(NSError *)error {
    NSLog(@"Discovered characteristics of service %@ of device %@:", service.UUID.UUIDString, peripheral.identifier.UUIDString);
    
    for (CBCharacteristic *ch in service.characteristics) {
        NSLog(@"Characteristic %@", ch.UUID.UUIDString);

        if ([ch.UUID.UUIDString isEqualToString:kCharUUID]) {
            self.characteristic = ch;
            [peripheral setNotifyValue:YES forCharacteristic:ch];
        }
    }
}

- (void) peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic
              error:(NSError *)error {
    NSLog(@"Characteristic %@ updated it's value", characteristic.UUID.UUIDString);
    if (_onNewData) _onNewData(characteristic.value, error);
}

- (void) writeValue:(NSData *)data {
    
    
    [_peripheral writeValue:data forCharacteristic:_characteristic type:CBCharacteristicWriteWithoutResponse];
}

#pragma mark - Singleton

static BTManager *instance = nil;

+ (BTManager *) sharedInstance {
    @synchronized(self) {
        if (instance == nil) {
            instance = [BTManager new];
        }
    }
    return instance;
}


@end
