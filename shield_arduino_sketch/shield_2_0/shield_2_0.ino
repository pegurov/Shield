// VERSION 0.0.3

// INCLUDES
#include <OneWire.h>
#include <DallasTemperature.h>
#include <SoftwareSerial.h>
#include <EEPROM.h>

/* ------------------------------------ API DEFINES ------------------------------------ */
#define COMMAND_SET_HEAT 0x01 // 01
#define COMMAND_SET_MODE 0x02 // 02
// getters
#define COMMAND_GET_STATE 0x03 // 03

// Commands that arduino sends to the phone
#define COMMAND_STATE_IS 0x65 // 101

// ARDUINO PROPERTIES
#define modeMemoryLocation 0x00
#define heatMemoryLocation 0x01
byte lastPhoneCommandByte = 0;
int currentMode = 0;
int currentHeat = 0;
int isCharging = 0;                  // 0 - not charging, 1 - charging
float currentTemperature = 0;        // last scanned temperature from //sensor
int currentBatteryLevel = 0;         // среднее арифметическое от 10 значений в секунду
int batteryLevels[20];

// PIN DEFINES
#define logoPin 9
#define heatPin 10
#define chargePin A2
#define batteryPin A1
#define temperaturePin 4
#define ARDUINO_SOFT_Rx 11
#define ARDUINO_SOFT_Tx 12

#define BAUD_RATE 57600

// temperature sensor
OneWire oneWire(temperaturePin);
DallasTemperature sensor(&oneWire);

// Shields UART is connected through SoftwareSerial
SoftwareSerial HM11(ARDUINO_SOFT_Rx, ARDUINO_SOFT_Tx);

// OTHERS
int AUTO_MODE_HEAT_LEVEL = 50;
int loopCounter = 0;

/* ------------------------------------ CODE ------------------------------------ */
// SETUP
void setup() {
 
  // setup pins
  pinMode(logoPin, OUTPUT);
  pinMode(heatPin, OUTPUT);
  pinMode(chargePin, INPUT);
  pinMode(ARDUINO_SOFT_Rx, INPUT);
  pinMode(ARDUINO_SOFT_Tx, OUTPUT);
  
  // see if there were heat and mode values in memory
  byte modeInMemory = EEPROM.read(modeMemoryLocation);
  byte heatInMemory = EEPROM.read(heatMemoryLocation);
  if (modeInMemory<=1) { 
    setMode(modeInMemory);
  }
  else {
    setMode(0);
  }
  
  if (heatInMemory<=100) {
    setHeat(heatInMemory);
  }
  else {
    setHeat(0);
  }
  
  // setup sensors and UARTs
  sensor.begin(); // start the temperature //sensor
  Serial.begin(BAUD_RATE);
  HM11.begin(BAUD_RATE);
  
  currentBatteryLevel = -1;
  lastPhoneCommandByte = COMMAND_GET_STATE;
}


// LOOP ---------------------------------------
void loop() {
  delay(50); // make an intentional delay
  boolean needToSendState = false; 
   
 // we have 100 beats
  if (loopCounter == 100) {
    loopCounter = 0; // LOOP COUNTER IS ZEROED HERE
  }
  
  if (loopCounter == 0) {
  // temperature
    sensor.requestTemperatures();
    float scannedTemperature = sensor.getTempCByIndex(0);
    if (scannedTemperature != currentTemperature) {
      currentTemperature = scannedTemperature;
      needToSendState = true;
    } 
    
  // battery level
    if (currentBatteryLevel == -1) {
      // first ever loop
      currentBatteryLevel = analogRead(batteryPin);
      needToSendState = true;
      
    }
    else {
      // calculate now battery level
      int nowBatteryLevel = 0;
      for (int i=0; i<20; i++) {
        nowBatteryLevel += batteryLevels[i];
      }
      nowBatteryLevel = (int)((float)nowBatteryLevel/20.);
      
      // see if we need to send it to the phone
      if (currentBatteryLevel != nowBatteryLevel) {
        currentBatteryLevel = nowBatteryLevel;
        needToSendState = true;
      }
    }
  }
  else if (loopCounter%5 == 0) {
    batteryLevels[(int)loopCounter/5] = analogRead(batteryPin);
  }
  loopCounter++;  // increment loop counter
   
// check if Shield changed charging status
  int isNowCharging = analogRead(chargePin);
  if (isNowCharging > 100) {
    if (isCharging == 0) {
      isCharging = 1;
      needToSendState = true;
    }
  }
  else {
    if (isCharging == 1) {
      isCharging = 0;
      needToSendState = true;
    }
  }  
   
// READING FROM PHONE
  if (HM11.available()>0) { // if there are any bytes
    byte receivedBytesCount = HM11.available();
    byte receivedBytes[receivedBytesCount];
    
    int counter = 0;
    while (HM11.available() > 0) { // read all bytes from HM11
      byte nextByte = HM11.read();
      Serial.print((char)nextByte);
      receivedBytes[counter] = nextByte;      
      counter++; // increment counter
    }
    
    if (receivedBytes[0] == COMMAND_SET_HEAT && receivedBytesCount == 2) {
      setHeat((int)receivedBytes[1]);
      needToSendState = true;
      lastPhoneCommandByte = COMMAND_SET_HEAT;
    }
    else if (receivedBytes[0] == COMMAND_SET_MODE && receivedBytesCount == 2) {
      setMode((int)receivedBytes[1]);
      needToSendState = true;
      lastPhoneCommandByte = COMMAND_SET_MODE;
    }
    else if (receivedBytes[0] == COMMAND_GET_STATE && receivedBytesCount == 1) {
      needToSendState = true;
      lastPhoneCommandByte = COMMAND_GET_STATE;
    }
  } 
  
// READ FROM SERIAL AND TRANSMIT COMMAND TO HM11
// THIS IS FOR DEBUG THROUGH SERIAL MONITIR (writing AT commands to the serial monitor)
  if (Serial.available()) {//check if there's any data sent from the local serial terminal, you can add the other applications here
    while (Serial.available() > 0) {
      char recvChar  = Serial.read();
      HM11.print(recvChar);
    }
  }
  
  if (needToSendState) {
    sendStateToPhone();
  }
}


// ACTIONS ------------------------------------------------
void setHeat(int heat) {
  currentHeat = heat;
  EEPROM.write(heatMemoryLocation, heat);
  analogWrite(heatPin, map(heat, 0, 100, 0, 255));
  analogWrite(logoPin, map(heat, 0, 100, 0, 255));
}

void setMode(int mode) {
  currentMode = mode;
  EEPROM.write(modeMemoryLocation, mode);
  if (mode == 1) { // auto
    setHeat(AUTO_MODE_HEAT_LEVEL); 
  }
}

void sendStateToPhone() {
  HM11.write((byte)COMMAND_STATE_IS);
  HM11.write((byte)lastPhoneCommandByte);
  HM11.write((byte)currentMode);
  
  int batteryLevelToSend = currentBatteryLevel;
  if (currentBatteryLevel < 470) { batteryLevelToSend = 470; }
  if (currentBatteryLevel > 800) { batteryLevelToSend = 800; }
  HM11.write((byte) map(batteryLevelToSend, 470, 800, 0, 100));
//  HM11.write((byte) map(currentBatteryLevel, 0, 1023, 0, 255));
  
  HM11.write((byte)currentHeat);
  HM11.write((byte)isCharging);
  
  // from -50 to +200 (0-255)
  int currentIntTemperature = (int)currentTemperature + 50;
  if (currentIntTemperature<0) { currentIntTemperature = 0;}
  if (currentIntTemperature>250) { currentIntTemperature = 250;} 
  HM11.write((byte)currentIntTemperature);
}
