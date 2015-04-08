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

@property (nonatomic, copy) void (^connectToShieldCompletionBlock)(BOOL successful);
@property (nonatomic, copy) void (^getStateCompletionBlock)(BOOL successful);
@property (nonatomic, copy) void (^ATCommandCompletionBlock)(BOOL successful, NSString *response);

// flags
@property (nonatomic) BOOL isScanning;
@property (strong, nonatomic) NSTimer *connectTimeoutTimer;
@property (strong, nonatomic) NSTimer *stateTimeoutTimer;
@property (strong, nonatomic) NSTimer *ATCommandTimeoutTimer;
@end

@implementation BTManager

//----------------------------------------------------------------------------------------
#pragma mark - NSObject

- (id)init {
    self = [super init];
    if (self) {
        self.centralBTManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
        self.discoveredShields = [NSMutableArray array];
        self.isScanning = NO;
    }
    return self;
}

//----------------------------------------------------------------------------------------
#pragma mark - Shared instance

+ (BTManager *) sharedInstance {
    static BTManager *__instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        __instance = [[BTManager alloc] init];
    });
    return __instance;
}

//----------------------------------------------------------------------------------------
#pragma mark - Searching / connecting to shield

- (void)scanForShieldsForSeconds:(NSInteger)seconds {
    [self stopScanningForShields];
    
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

- (void)stopScanningForShields {
    self.isScanning = NO;
    [self.centralBTManager stopScan];
    if ([self.delegate respondsToSelector:@selector(btManagerDidEndScanningForShields:)]) {
        [self.delegate btManagerDidEndScanningForShields:self];
    }
}

- (void)connectToShield:(Shield *)shield completionBlock:(void (^)(BOOL successful))completionBlock {
    if (shield.peripheral.state == CBPeripheralStateDisconnected) {
        self.connectToShieldCompletionBlock = completionBlock;
        [self.centralBTManager connectPeripheral:shield.peripheral options:nil];
        self.connectTimeoutTimer = [NSTimer scheduledTimerWithTimeInterval:5 // 5 secs timeout
                                                                    target:self
                                                                  selector:@selector(connectTimeoutHandler)
                                                                  userInfo:nil
                                                                   repeats:NO];
    }
    else {
        if (completionBlock) {
            completionBlock(NO);
        }
    }
}

- (void)connectTimeoutHandler {
    if (self.connectToShieldCompletionBlock) {
        self.connectToShieldCompletionBlock(NO);
        self.connectToShieldCompletionBlock = nil;
        [self.connectTimeoutTimer invalidate];
        NSLog(@"WARNING: Could not connect to shield, stopping wait on timeout");
    }
}

- (void)disconnectFromConnectedShield {
    if (self.connectedShield) {
        [self.centralBTManager cancelPeripheralConnection:self.connectedShield.peripheral];
        self.connectedShield = nil;
    }
}

//----------------------------------------------------------------------------------------
#pragma mark - CBCentralManagerDelegate

- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
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
     advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI {
    if (![self.discoveredShields containsObject:peripheral]) {
        
        Shield *newDevice = [[Shield alloc] init];
        newDevice.peripheral = peripheral;
        [self.discoveredShields addObject:newDevice];
        if ([self.delegate respondsToSelector:@selector(btManagerUpdatedDiscoveredShields:)]) {
            [self.delegate btManagerUpdatedDiscoveredShields:self];
        }
    }
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
    // we consider a device connected only ahen all
    // charachteristics for its MAIN SERVICE have been found
    [peripheral setDelegate:self];
    [peripheral discoverServices:nil];
}

- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    if (self.connectToShieldCompletionBlock) {
        self.connectToShieldCompletionBlock(NO);
        self.connectToShieldCompletionBlock = nil;
        [self.connectTimeoutTimer invalidate];
        NSLog(@"WARNING: Could not connect to shield, BT manager error: %@", error);
    }
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    NSLog(@"Disconnected from %@", peripheral.identifier.UUIDString);
    self.connectedShield = nil;
    if ([self.delegate respondsToSelector:@selector(btManagerDidDisconnectFromShield:)]) {
        [self.delegate btManagerDidDisconnectFromShield:self];
    }
}

//----------------------------------------------------------------------------------------
#pragma mark - CBPeripheralDelegate

- (void)peripheralDidUpdateRSSI:(CBPeripheral *)peripheral error:(NSError *)error {
    if ([self.connectedShield.delegate respondsToSelector:@selector(shieldDidUpdate:)]) {
        [self.connectedShield.delegate shieldDidUpdate:self.connectedShield];
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error {
    for (CBService *service in peripheral.services)
    {
        if ([service.UUID.UUIDString isEqualToString:SHIELD_MAIN_SERVICE_UUID]) {
            [peripheral discoverCharacteristics:nil forService:service];
        }
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error {
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
        
        self.connectedShield = shieldWeAreConnectingTo;
        [self.discoveredShields removeObject:self.connectedShield];
        
        if (self.connectToShieldCompletionBlock) {
            self.connectToShieldCompletionBlock(self.connectedShield);
        }
        self.connectToShieldCompletionBlock = nil;
        [self.connectTimeoutTimer invalidate];
    }
}

//----------------------------------------------------------------------------------------
#pragma mark - Setting / Requesting values from connected shield

- (void)setHeat:(NSInteger)heat {
    unsigned char commandByte = COMMAND_SET_HEAT;
    unsigned char valueByte = 0x64 * (heat/100.); // 0x64 is 100 in hex
    unsigned char bytesToSend[2] = {commandByte, valueByte};
    [self writeToConecttedShield:[NSMutableData dataWithBytes:&bytesToSend length:sizeof(bytesToSend)]];
}

- (void)setMode:(ShieldMode)mode {
    unsigned char commandByte = COMMAND_SET_MODE;
    unsigned char valueByte = (mode==ShieldModeManual)? 0x00 : 0x01; // 0x00 - manual, 0x01 - auto
    unsigned char bytesToSend[2] = {commandByte, valueByte};
    [self writeToConecttedShield:[NSMutableData dataWithBytes:&bytesToSend length:sizeof(bytesToSend)]];
}

- (void)getStateWithCompletionBlock:(void (^)(BOOL successful))completionBlock {
    if (!self.getStateCompletionBlock) {
        self.getStateCompletionBlock = completionBlock;
        unsigned char commandByte = COMMAND_GET_STATE;
        unsigned char bytesToSend[1] = {commandByte};

        [self writeToConecttedShield:[NSMutableData dataWithBytes:&bytesToSend length:sizeof(bytesToSend)]];
        self.stateTimeoutTimer = [NSTimer scheduledTimerWithTimeInterval:2 // 2 secs timeout
                                                                  target:self
                                                                selector:@selector(stateTimeoutHandler)
                                                                userInfo:nil
                                                                 repeats:NO];
    }
    else {
#warning TODO - make this possible
        NSLog(@"WARNING: cannot get heat from shield, waiting for a response!");
    }
}

- (void)stateTimeoutHandler {
    if (self.getStateCompletionBlock) {
        self.getStateCompletionBlock(NO);
        self.getStateCompletionBlock = nil;
        NSLog(@"WARNING: Could not get state, stopping wait on timeout");
    }
}

- (void)sendATCommandToHM11:(NSString *)command
                    timeout:(NSInteger)timeout
            completionBlock:(void (^)(BOOL successful, NSString *response))completionBlock {
    if (!self.ATCommandCompletionBlock) {
        self.ATCommandCompletionBlock = completionBlock;
        [self writeToConecttedShield:[command dataUsingEncoding:NSASCIIStringEncoding]];
        self.ATCommandTimeoutTimer = [NSTimer scheduledTimerWithTimeInterval:timeout
                                                                      target:self
                                                                    selector:@selector(ATCommandTimeoutHandler)
                                                                    userInfo:nil
                                                                     repeats:NO];
    }
}

- (void)ATCommandTimeoutHandler {
    if (self.ATCommandCompletionBlock) {
        self.ATCommandCompletionBlock(NO, nil);
        self.ATCommandCompletionBlock = nil;
        NSLog(@"WARNING: Did not get response for AT command, stopping wait on timeout");
    }
}

//----------------------------------------------------------------------------------------
#pragma mark - Shield writing and updating values

- (void)writeToConecttedShield:(NSData *)data {
    // LOGGING
    unsigned char outgoingBytes[data.length];
    [data getBytes:outgoingBytes length:data.length];
    
    if (data.length>=2 && outgoingBytes[0] == COMMAND_SET_HEAT) {
        NSLog(@"REQUEST -> setting HEAT LEVEL to: %@", @((int)outgoingBytes[1]));
    }
    else if (data.length>=2 && outgoingBytes[0] == COMMAND_SET_MODE) {
        NSLog(@"REQUEST -> setting MODE to: %@", @((int)outgoingBytes[1]));
    }
    else if (data.length>=1 && outgoingBytes[0] == COMMAND_GET_STATE) {
        NSLog(@"REQUEST -> requesting STATE");
    }
    else if (data.length>=3 && outgoingBytes[0] == 'A' && outgoingBytes[1] == 'T' && outgoingBytes[2] == '+') {
        NSLog(@"REQUEST -> sending AT command: %@", [[NSString alloc] initWithBytes:outgoingBytes length:data.length encoding:NSASCIIStringEncoding]);
    }
    else {
        NSLog(@"WARNING: sending an unauthorised command to shield! :%@", data);
    }
    
    [self writeValueToPeripheral:self.connectedShield.peripheral data:data];
}

- (void)writeValueToPeripheral:(CBPeripheral *)peripheral
                          data:(NSData *)data {
    CBUUID *mainServiceUUID = [CBUUID UUIDWithString:SHIELD_MAIN_SERVICE_UUID];
    CBUUID *rxCharUUID = [CBUUID UUIDWithString:SHIELD_CHAR_RX_UUID];
    
    CBCharacteristic *foundCharcteristic = [peripheral findCharacteristicForServiceUUID:mainServiceUUID characteristicUUID:rxCharUUID];
    
    if (foundCharcteristic) {
        [self addDataToLog:data isOutgoing:YES];
        [peripheral writeValue:data forCharacteristic:foundCharcteristic type:CBCharacteristicWriteWithoutResponse];
    }
    else {
        NSLog(@"Could not write to characteristic with UUID %@ on peripheral %@", rxCharUUID, peripheral);
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    if (characteristic.value.length>0) {
        NSData *rawData = characteristic.value;
        [self addDataToLog:rawData isOutgoing:NO];
        
        unsigned char incomingBytes[rawData.length];
        [rawData getBytes:incomingBytes length:rawData.length];

        char firstByte = incomingBytes[0];
        if (firstByte == COMMAND_STATE_IS && rawData.length >= 6) {

            // we have 5 more bytes in the message
            // mode, batteryLevel, heat, isCharging, temperature
            NSLog(@"RESPONSE <- current SHIELD STATE %@", rawData);
            
            self.connectedShield.mode = (int)incomingBytes[1] == 0? ShieldModeManual : ShieldModeAuto;
            self.connectedShield.batteryLevel = (int)incomingBytes[2];
            self.connectedShield.heat = (int)incomingBytes[3];
            self.connectedShield.isCharging = (int)incomingBytes[4] == 0? NO : YES;
            self.connectedShield.temperature = (CGFloat)incomingBytes[5] - 50.;
            
            if ([self.connectedShield.delegate respondsToSelector:@selector(shieldDidUpdate:)]) {
                [self.connectedShield.delegate shieldDidUpdate:self.connectedShield];
            }
            
            if (self.getStateCompletionBlock) {
                [self.stateTimeoutTimer invalidate];
                self.getStateCompletionBlock(YES);
                self.getStateCompletionBlock = nil;
            }
        }
        else if (firstByte == AT_RESPONSE_START) {
            // we have an AT command response
            NSString *ATCommandResponse = [[NSString alloc] initWithData:rawData encoding:NSASCIIStringEncoding];
            NSLog(@"RESPONSE <- AT response %@", ATCommandResponse);
            
            if (self.ATCommandCompletionBlock) {
                [self.ATCommandTimeoutTimer invalidate];
                void (^localBlock)(BOOL successful, NSString *response) = self.ATCommandCompletionBlock;
                self.ATCommandCompletionBlock = nil;
                localBlock(YES, ATCommandResponse);
            }
        }
    }
}

- (void)addDataToLog:(NSData *)data isOutgoing:(BOOL)outgoing {
    if (!self.connectedShield.ASCIIlog) self.connectedShield.ASCIIlog = @"";
    if (!self.connectedShield.HEXlog) self.connectedShield.HEXlog = @"";
    
    NSString *ASCIIstringMessage = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
    NSString *ASCIImessageToAdd = [NSString stringWithFormat:@"%@:%@\n",outgoing?@"WR" : @"RE", ASCIIstringMessage];
    self.connectedShield.ASCIIlog = [ASCIImessageToAdd stringByAppendingString:self.connectedShield.ASCIIlog];

    NSString *HEXCharsString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    unsigned short len = [HEXCharsString length];
    NSMutableArray *arr = [NSMutableArray arrayWithCapacity:len];
    for (unsigned i = 0; i < len; ++i) {
        [arr addObject:[NSNumber numberWithUnsignedShort:[HEXCharsString characterAtIndex:i]]];
    }
    
    NSString *intByteValuesString = outgoing? @"WR:" : @"RE:";
    for (NSNumber *someByte in arr) {
        intByteValuesString = [intByteValuesString stringByAppendingFormat:@"%03ld ", (long)someByte.integerValue];
    }
    intByteValuesString = [intByteValuesString stringByAppendingString:@"\n"];
    self.connectedShield.HEXlog = [intByteValuesString stringByAppendingString:self.connectedShield.HEXlog];
    
    if ([self.connectedShield.delegate respondsToSelector:@selector(shieldDidUpdateLog:)]) {
        [self.connectedShield.delegate shieldDidUpdateLog:self.connectedShield];
    }
}

@end

@implementation CBPeripheral (Additions)

- (CBCharacteristic *)findCharacteristicForServiceUUID:(CBUUID *)serviceUUID characteristicUUID:(CBUUID *)charUUID {
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

