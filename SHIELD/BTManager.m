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
@property (nonatomic, copy) void (^ATCommandCompletionBlock)(BOOL successful, NSString *response);

@property (nonatomic, copy) void (^getStateCompletionBlock)(BOOL successful);
@property (nonatomic, copy) void (^setModeCompletionBlock)(BOOL successful);
@property (nonatomic, copy) void (^setHeatCompletionBlock)(BOOL successful);
@property (nonatomic, copy) void (^passwordCompletionBlock)(BOOL successful);

// flags
@property (nonatomic) BOOL isScanning;
@property (strong, nonatomic) NSTimer *connectTimeoutTimer;
@property (strong, nonatomic) NSTimer *ATCommandTimeoutTimer;

@property (strong, nonatomic) NSTimer *stateTimeoutTimer;
@property (strong, nonatomic) NSTimer *modeTimeoutTimer;
@property (strong, nonatomic) NSTimer *heatTimeoutTimer;
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
    if (self.isScanning) {
        self.isScanning = NO;
        [self.centralBTManager stopScan];
        if ([self.delegate respondsToSelector:@selector(btManagerDidEndScanningForShields:)]) {
            [self.delegate btManagerDidEndScanningForShields:self];
        }
    }
}

- (void)connectToShield:(Shield *)shield completionBlock:(void (^)(BOOL successful))completionBlock {
    if (shield.peripheral.state == CBPeripheralStateDisconnected) {
        self.connectToShieldCompletionBlock = completionBlock;
        [self.centralBTManager connectPeripheral:shield.peripheral options:@{CBConnectPeripheralOptionNotifyOnDisconnectionKey:@(YES)}];
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

        if ([self.delegate respondsToSelector:@selector(btManagerUpdatedDiscoveredShields:)]) {
            [self.delegate btManagerUpdatedDiscoveredShields:self];
        }
        if ([self.delegate respondsToSelector:@selector(btManagerDidDisconnectFromShield:)]) {
            [self.delegate btManagerDidDisconnectFromShield:self];
        }
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

    BOOL discoveredPeripheralIsConnectedOrIsAlreadyInDiscoveredList = NO;
    
    for (Shield *someShield in self.discoveredShields) {
        if ([someShield.peripheral isEqual:peripheral]) {
            discoveredPeripheralIsConnectedOrIsAlreadyInDiscoveredList = YES;
        }
    }
    if ([self.connectedShield.peripheral isEqual:peripheral]) {
        discoveredPeripheralIsConnectedOrIsAlreadyInDiscoveredList = YES;
    }
    
    if (!discoveredPeripheralIsConnectedOrIsAlreadyInDiscoveredList) {
        
        Shield *newDevice = [[Shield alloc] init];
        newDevice.peripheral = peripheral;
        [self.discoveredShields addObject:newDevice];
    }

    if ([self.delegate respondsToSelector:@selector(btManagerUpdatedDiscoveredShields:)]) {
        [self.delegate btManagerUpdatedDiscoveredShields:self];
    }
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
    // we consider a device connected only ahen all
    // charachteristics for its MAIN SERVICE have been found
    [peripheral setDelegate:self];
    [peripheral discoverServices:@[[CBUUID UUIDWithString:SHIELD_MAIN_SERVICE_UUID]]];
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
            [peripheral discoverCharacteristics:@[[CBUUID UUIDWithString:SHIELD_CHAR_RX_UUID]] forService:service];
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

- (void)validatePasswordWithCompletionBlock:(void (^)(BOOL successful))completionBlock {
    
    [[BTManager sharedInstance] sendATCommandToHM11:@"AT+PASS?" timeout:2 completionBlock:^(BOOL successful, NSString *response) {
        
        if ([response isEqualToString:@"OK+Get:000000"]) { // there is no password
            completionBlock(YES);
        }
        else { // need to enter password
            self.passwordCompletionBlock = completionBlock;
            self.connectedShield.password = [response substringFromIndex:7.];
            [self presentPasswordAlert];
        }
    }];
}

- (void)presentPasswordAlert {
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Password confirmation" message:@"To connect to this Shield, you need to eneter password" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"OK", nil];
    alertView.tag = 1234;
    alertView.alertViewStyle = UIAlertViewStylePlainTextInput;
    UITextField *passwordTextField = [alertView textFieldAtIndex:0];
    passwordTextField.keyboardType = UIKeyboardTypeNumberPad;
    
    [alertView show];
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (alertView.tag == 1234) {
        // password
        switch (buttonIndex) {
            case 0: { // cancel
                break;
            }
            case 1: { // confirmed
                
                UITextField *passwordTextField = [alertView textFieldAtIndex:0];
                if (passwordTextField.text && [passwordTextField.text isEqualToString:[BTManager sharedInstance].connectedShield.password]) {
                    self.passwordCompletionBlock(YES);
                }
                else {
                    self.passwordCompletionBlock(NO);
                    // show alert that password is wrong
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Wrong passcode" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                    [alert show];
                }
                break;
            }
            default: { }
                break;
        }
    }
}

// set heat
- (void)setHeat:(NSInteger)heat сompletionBlock:(void (^)(BOOL successful))completionBlock {
    self.setHeatCompletionBlock = completionBlock;
    [self.heatTimeoutTimer invalidate];
    self.heatTimeoutTimer = [NSTimer scheduledTimerWithTimeInterval:4
                                                              target:self
                                                            selector:@selector(heatTimeoutHandler)
                                                            userInfo:nil
                                                             repeats:NO];
    
    unsigned char commandByte = COMMAND_SET_HEAT;
    unsigned char valueByte = 0x64 * (heat/100.); // 0x64 is 100 in hex
    unsigned char bytesToSend[2] = {commandByte, valueByte};
    [self writeToConecttedShield:[NSMutableData dataWithBytes:&bytesToSend length:sizeof(bytesToSend)]];
}

- (void)heatTimeoutHandler {
    if (self.setHeatCompletionBlock) {
        self.setHeatCompletionBlock(NO);
        self.setHeatCompletionBlock = nil;
        NSLog(@"WARNING: Could not set heat, stopping wait on timeout");
    }
}

// set mode
- (void)setMode:(ShieldMode)mode сompletionBlock:(void (^)(BOOL successful))completionBlock {
    self.setModeCompletionBlock = completionBlock;
    [self.modeTimeoutTimer invalidate];
    self.modeTimeoutTimer = [NSTimer scheduledTimerWithTimeInterval:4
                                                              target:self
                                                            selector:@selector(modeTimeoutHandler)
                                                            userInfo:nil
                                                             repeats:NO];
    
    unsigned char commandByte = COMMAND_SET_MODE;
    unsigned char valueByte = (mode==ShieldModeManual)? 0x00 : 0x01; // 0x00 - manual, 0x01 - auto
    unsigned char bytesToSend[2] = {commandByte, valueByte};
    [self writeToConecttedShield:[NSMutableData dataWithBytes:&bytesToSend length:sizeof(bytesToSend)]];
}

- (void)modeTimeoutHandler {
    if (self.setModeCompletionBlock) {
        self.setModeCompletionBlock(NO);
        self.setModeCompletionBlock = nil;
        NSLog(@"WARNING: Could not set mode, stopping wait on timeout");
    }
}

// get state
- (void)getStateWithCompletionBlock:(void (^)(BOOL successful))completionBlock {
    self.getStateCompletionBlock = completionBlock;
    self.stateTimeoutTimer = [NSTimer scheduledTimerWithTimeInterval:4
                                                              target:self
                                                            selector:@selector(stateTimeoutHandler)
                                                            userInfo:nil
                                                             repeats:NO];
    
    unsigned char commandByte = COMMAND_GET_STATE;
    unsigned char bytesToSend[1] = {commandByte};
    [self writeToConecttedShield:[NSMutableData dataWithBytes:&bytesToSend length:sizeof(bytesToSend)]];
}

- (void)performActionsBeforeShowingShieldWithCompletionBlock:(void (^)(BOOL successful))completionBlock {
    
    [[BTManager sharedInstance] sendATCommandToHM11:@"AT+PIO2?" timeout:2 completionBlock:^(BOOL successful, NSString *response) {
        if (successful) {
            if ([response isEqualToString:@"OK+PIO2:0"]) {
                self.connectedShield.isOn = NO;
                completionBlock(YES);
            }
            else if ([response isEqualToString:@"OK+PIO2:1"]) {
                self.connectedShield.isOn = YES;
                [[BTManager sharedInstance] getStateWithCompletionBlock:^(BOOL successful) {
                    if (successful) {
                        completionBlock(YES);
                    }
                    else {
                        completionBlock(NO);
                    }
                }];
            }
            else {
                completionBlock(NO);
            }
        }
        else {
            completionBlock(NO);
        }
    }];
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

    self.ATCommandCompletionBlock = completionBlock;
    [self writeToConecttedShield:[command dataUsingEncoding:NSASCIIStringEncoding]];
    self.ATCommandTimeoutTimer = [NSTimer scheduledTimerWithTimeInterval:timeout
                                                                  target:self
                                                                selector:@selector(ATCommandTimeoutHandler)
                                                                userInfo:nil
                                                                 repeats:NO];
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
    else if (data.length>=2 && outgoingBytes[0] == 'A' && outgoingBytes[1] == 'T') {
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
            
            NSInteger lastPhoneCommandByte = (int)incomingBytes[1];
            
            self.connectedShield.mode = (int)incomingBytes[2] == 0? ShieldModeManual : ShieldModeAuto;
            if (self.connectedShield.batteryLevel != (int)incomingBytes[3]) {
                self.connectedShield.batteryLevel = (int)incomingBytes[3];
                UILocalNotification *batteryNotification = [[UILocalNotification alloc] init];
                batteryNotification.fireDate = [NSDate date];
                batteryNotification.alertTitle = @"Shield updated";
                batteryNotification.alertBody = [NSString stringWithFormat:@"Battery: %@", @(self.connectedShield.batteryLevel)];
                [[UIApplication sharedApplication] scheduleLocalNotification:batteryNotification];
            }
            self.connectedShield.heat = (int)incomingBytes[4];
            self.connectedShield.isCharging = (int)incomingBytes[5] == 0? NO : YES;
            self.connectedShield.temperature = (CGFloat)incomingBytes[6] - 50.;
            
            if ([self.connectedShield.delegate respondsToSelector:@selector(shieldDidUpdate:)]) {
                [self.connectedShield.delegate shieldDidUpdate:self.connectedShield];
            }
            
            if (lastPhoneCommandByte == COMMAND_GET_STATE) { // response to requesting state
                if (self.getStateCompletionBlock) {
                    [self.stateTimeoutTimer invalidate];
                    self.getStateCompletionBlock(YES);
                    self.getStateCompletionBlock = nil;
                }
            }
            else if (lastPhoneCommandByte == COMMAND_SET_MODE) { // response to setting mode
                if (self.setModeCompletionBlock) {
                    [self.modeTimeoutTimer invalidate];
                    self.setModeCompletionBlock(YES);
                    self.setModeCompletionBlock = nil;
                }
            }
            else if (lastPhoneCommandByte == COMMAND_SET_HEAT) { // response to setting heat
                if (self.setHeatCompletionBlock) {
                    [self.heatTimeoutTimer invalidate];
                    self.setHeatCompletionBlock(YES);
                    self.setHeatCompletionBlock = nil;
                }
            }
        }
        else if (firstByte == AT_RESPONSE_START) {
            // we have an AT command response
            NSString *ATCommandResponse = [[NSString alloc] initWithData:rawData encoding:NSASCIIStringEncoding];
            NSLog(@"RESPONSE <- AT response %@", ATCommandResponse);
            
            if (self.ATCommandCompletionBlock) {
                
                void (^localBlock)(BOOL successful, NSString *response) = self.ATCommandCompletionBlock;
                self.ATCommandCompletionBlock = nil;
                [self.ATCommandTimeoutTimer invalidate];
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

