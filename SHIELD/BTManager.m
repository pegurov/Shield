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

@property (nonatomic, copy) void (^getHeatCompletionBlock)(Shield *shield);
@property (nonatomic, copy) void (^getModeCompletionBlock)(Shield *shield);
@property (nonatomic, copy) void (^getTemperatureCmpletionBlock)(Shield *shield);

@property (nonatomic, copy) void (^connectToShieldCompletionBlock)(Shield *shield);

// flags
@property (nonatomic) BOOL isScanning;
@property (strong, nonatomic) NSTimer *heatTimeoutTimer;
@property (strong, nonatomic) NSTimer *modeTimeoutTimer;
@property (strong, nonatomic) NSTimer *temperatureTimeoutTimer;
@end

@implementation BTManager

//----------------------------------------------------------------------------------------
#pragma mark - NSObject

- (id)init
{
    self = [super init];
    if (self) {
        self.centralBTManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
        self.discoveredShields = [NSMutableArray array];
        self.isScanning = NO;
    }
    return self;
}

//----------------------------------------------------------------------------------------
#pragma mark - public API

+ (BTManager *) sharedInstance
{
    static BTManager *__instance = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        __instance = [[BTManager alloc] init];
    });
    return __instance;
}

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

- (void)connectToShield:(Shield *)shield completionBlock:(void (^)(Shield *connectedShield))completionBlock;
{
    if (shield.peripheral.state == CBPeripheralStateDisconnected) {
        self.connectToShieldCompletionBlock = completionBlock;
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
        self.connectedShield = nil;
    }
}


//----------------------------------------------------------------------------------------
// setting and requesting values with conected shield
- (void)setHeat:(NSInteger)heat {
    unsigned char commandByte = COMMAND_SET_HEAT;
    unsigned char valueByte = 0x64 * (heat/100.); // 0x64 is 100 in hex
    unsigned char bytesToSend[2] = {commandByte, valueByte};
    [self writeToConecttedShield:[NSMutableData dataWithBytes:&bytesToSend length:sizeof(bytesToSend)]];
}

- (void)getHeatWithCompletionBlock:(void (^)(Shield *shield))completionBlock {
    if (!self.getHeatCompletionBlock) {
        self.getHeatCompletionBlock = completionBlock;
        unsigned char commandByte = COMMAND_GET_HEAT;
        unsigned char bytesToSend[1] = {commandByte};

        [self writeToConecttedShield:[NSMutableData dataWithBytes:&bytesToSend length:sizeof(bytesToSend)]];
        self.heatTimeoutTimer = [NSTimer scheduledTimerWithTimeInterval:5 // 5 secs timeout
                                                                 target:self
                                                               selector:@selector(heatTimeoutHandler)
                                                               userInfo:nil
                                                                repeats:NO];
    }
    else {
#warning TODO - make this possible
        NSLog(@"WARNING: cannot get heat from shield, waiting for a response!");
    }
}

- (void)setMode:(ShieldMode)mode {
    unsigned char commandByte = COMMAND_SET_MODE;
    unsigned char valueByte = (mode==ShieldModeManual)? 0x00 : 0x01; // 0x00 - manual, 0x01 - auto
    unsigned char bytesToSend[2] = {commandByte, valueByte};
    [self writeToConecttedShield:[NSMutableData dataWithBytes:&bytesToSend length:sizeof(bytesToSend)]];
}

- (void)getModeWithCompletionBlock:(void (^)(Shield *shield))completionBlock {
    if (!self.getModeCompletionBlock) {
        self.getModeCompletionBlock = completionBlock;
        unsigned char commandByte = COMMAND_GET_MODE;
        unsigned char bytesToSend[1] = {commandByte};

        [self writeToConecttedShield:[NSMutableData dataWithBytes:&bytesToSend length:sizeof(bytesToSend)]];
        self.modeTimeoutTimer = [NSTimer scheduledTimerWithTimeInterval:5 // 5 secs timeout
                                                                 target:self
                                                               selector:@selector(modeTimeoutHandler)
                                                               userInfo:nil
                                                                repeats:NO];
    }
    else {
#warning TODO - make this possible
        NSLog(@"WARNING: cannot get mode from shield, waiting for a response!");
    }
}

- (void)getTemperatureWithCompletionBlock:(void (^)(Shield *shield))completionBlock
{
    if (!self.getTemperatureCmpletionBlock) {
        self.getTemperatureCmpletionBlock = completionBlock;
        unsigned char commandByte = COMMAND_GET_TEMPERATURE;
        unsigned char bytesToSend[1] = {commandByte};

        [self writeToConecttedShield:[NSMutableData dataWithBytes:&bytesToSend length:sizeof(bytesToSend)]];
        self.temperatureTimeoutTimer = [NSTimer scheduledTimerWithTimeInterval:5 // 5 secs timeout
                                                                        target:self
                                                                      selector:@selector(temperatureTimeoutHandler)
                                                                      userInfo:nil
                                                                       repeats:NO];
    }
    else {
#warning TODO - make this possible
        NSLog(@"WARNING: cannot get mode from shield, waiting for a response!");
    }
}

- (void)heatTimeoutHandler
{
    if (self.getHeatCompletionBlock) {
       self.getHeatCompletionBlock = nil;
        NSLog(@"WARNING: Could not get heat, stopping wait on timeout");
    }
}

- (void)modeTimeoutHandler
{
    if (self.getModeCompletionBlock) {
        self.getModeCompletionBlock = nil;
        NSLog(@"WARNING: Could not get mode, stopping wait on timeout");
    }
}

- (void)temperatureTimeoutHandler
{
    if (self.getTemperatureCmpletionBlock) {
        self.getTemperatureCmpletionBlock = nil;
        NSLog(@"WARNING: Could not get temperature, stopping wait on timeout");
    }
}


//----------------------------------------------------------------------------------------
#pragma mark - Shield writing and updating values

// writing
- (void)writeToConecttedShield:(NSData *)data
{
    // LOGGING
    NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    unsigned short len = [string length];
    NSMutableArray *arr = [NSMutableArray arrayWithCapacity:len];
    for (unsigned i = 0; i < len; ++i) {
        [arr addObject:[NSNumber numberWithUnsignedShort:[string characterAtIndex:i]]];
    }

    if ([[arr firstObject] isEqual:@(COMMAND_SET_HEAT)]) {
        NSLog(@"REQUEST -> setting HEAT LEVEL to: %@", [arr lastObject]);
    }
    else if ([[arr firstObject] isEqualToNumber:@(COMMAND_GET_HEAT)]) {
        NSLog(@"REQUEST -> requesting HEAT LEVEL");
    }
    else if ([[arr firstObject] isEqual:@(COMMAND_SET_MODE)]) {
        NSLog(@"REQUEST -> setting MODE to: %@", [[arr lastObject] isEqual:@(0)] ? @"manual" : @"auto");
    }
    else if ([[arr firstObject ]isEqual:@(COMMAND_GET_MODE)]) {
        NSLog(@"REQUEST -> requesting MODE");
    }
    else if ([[arr firstObject ]isEqual:@(COMMAND_GET_IS_CHARGING)]) {
        NSLog(@"REQUEST -> requesting IS CHARGING");
    }
    else if ([[arr firstObject ]isEqual:@(COMMAND_GET_BATTERY_LEVEL)]) {
        NSLog(@"REQUEST -> requesting BATTERY LEVEL");
    }
    else if ([[arr firstObject ]isEqual:@(COMMAND_GET_TEMPERATURE)]) {
        NSLog(@"REQUEST -> requesting TEMPERATURE");
    }
    else {
        NSLog(@"WARNING: sending an unauthorised command to shield! :%@", arr);
    }
    
    // actual writing
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

// getting notifications
- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    NSData *rawData = characteristic.value;
    unsigned char incomingBytes[rawData.length];
    [rawData getBytes:incomingBytes length:rawData.length];
    
    NSMutableArray *commandPairs = [NSMutableArray array];
    
    // parse scanned strings into array of pairs
    NSMutableArray *newPair = [NSMutableArray array];
    for (int i = 0; i<rawData.length; i++) {
        [newPair addObject:@(incomingBytes[i])];
        
        if (newPair.count==2) {
            [commandPairs addObject:[newPair copy]];
            newPair = [NSMutableArray array];
        }
    }
    
    for (NSMutableArray *commandValuePair in commandPairs) {
    
        NSInteger commandByte = [[commandValuePair firstObject] integerValue];
        NSInteger valueByte = [[commandValuePair lastObject] integerValue];
    
        if (commandByte == COMMAND_HEAT_IS) {
            
            NSLog(@"RESPONSE <- current HEAT LEVEL is: %@", @(valueByte));
            
            self.connectedShield.heat = valueByte;
            if (self.getHeatCompletionBlock) {
                [self.heatTimeoutTimer invalidate];
                self.getHeatCompletionBlock(self.connectedShield);
                self.getHeatCompletionBlock = nil;
            }
        }
        else if (commandByte == COMMAND_MODE_IS) {
            
            NSLog(@"RESPONSE <- current MODE is: %@", valueByte==0? @"manual" : @"auto" );
            
            self.connectedShield.mode = valueByte;
            if (self.getModeCompletionBlock) {
                [self.modeTimeoutTimer invalidate];
                self.getModeCompletionBlock(self.connectedShield);
                self.getModeCompletionBlock = nil;
            }
        }
        else if (commandByte == COMMAND_TEMPERATURE_IS) {
            
            NSLog(@"RESPONSE <- current TEMPERATURE is: %@", @(valueByte));
            
            self.connectedShield.temperature = @(valueByte-50);
            if (self.getTemperatureCmpletionBlock) {
                [self.temperatureTimeoutTimer invalidate];
                self.getTemperatureCmpletionBlock(self.connectedShield);
                self.getTemperatureCmpletionBlock = nil;
            }
        }
        else if (commandByte == COMMAND_IS_CHARGING) {
            
            NSLog(@"RESPONSE <- is CHARGING: %@", valueByte==0? @"NO" : @"YES");
            self.connectedShield.isCharging = valueByte==0? NO : YES;
        }
        else if (commandByte == COMMAND_BATTERY_LEVEL_IS) {
            
            NSLog(@"RESPONSE <- current BATTERY LEVEL is: %@", @(valueByte));
            self.connectedShield.batteryLevel = valueByte;
        }
        else {
            NSLog(@"RESPONSE: got some value from shield : %@", rawData);
        }
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
    self.connectedShield = nil;
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

//       [self getModeWithCompletionBlock:^(Shield *shield) {
//            [self getHeatWithCompletionBlock:^(Shield *shield) {
//                [self getTemperatureWithCompletionBlock:^(Shield *shield) {
                    if (self.connectToShieldCompletionBlock) {
                        self.connectToShieldCompletionBlock(self.connectedShield);
                    }
//                }];
//           }];
//        }];
    }
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

