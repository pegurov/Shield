// VERSION 0.0.3

// INCLUDES
#include <OneWire.h>
#include <DallasTemperature.h>
#include <SoftwareSerial.h>

/* ------------------------------------ API DEFINES ------------------------------------
The phone talks to arduino and arduino talks back to the phone by sending 1 or 2 byte long commands.
Some of the commands need an additional value byte, example - SET_HEAT_LEVEL
Some of the commands don't, example - GET_HEAT_LEVEL
*/

// Commands that the phone sends to arduino
const int COMMAND_SET_HEAT = 1; // Needs an additional value byte, indicating heat level. Range is [0..100]
const int COMMAND_GET_HEAT = 2;
const int COMMAND_SET_MODE = 3; // Needs an additional value byte, indicating mode. 0 - manual, 1 - auto
const int COMMAND_GET_MODE = 4;
const int COMMAND_GET_IS_CHARGING = 5;
const int COMMAND_GET_BATTERY_LEVEL = 6;
const int COMMAND_GET_TEMPERATURE = 7;

// Commands that arduino sends to the phone
const int COMMAND_HEAT_IS = 101; // Sending back current heat level
const int COMMAND_MODE_IS = 102; // Sending back current mode
const int COMMAND_IS_CHARGING = 103; // Sending back charging status
const int COMMAND_BATTERY_LEVEL_IS = 104; // Sending back battery level
const int COMMAND_TEMPERATURE_IS = 105; // Sending back battery level

// ARDUINO PROPERTIES
int currentHeat = 0;                 // Range is [0..100]
int currentMode = 0;                 // 0 - manual, 1 - auto
int isCharging = 0;                  // 0 - not charging, 1 - charging
float currentTemperature = 0;        // last scanned temperature from //sensor
int currentBatteryLevel = 0;        // среднее арифметическое от 10 значений в секунду
int battteryLevels[30] = {0,0,0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0,0,0};

// PIN DEFINES
#define logoPin 9
#define heatPin 10
#define chargePin A2
#define batteryPin A1
#define temperaturePin 4
#define ARDUINO_SOFT_Rx 11
#define ARDUINO_SOFT_Tx 12

#define BAUD_RATE 115200

// temperature sensor
OneWire oneWire(temperaturePin);
DallasTemperature sensor(&oneWire);

// Shields UART is connected through SoftwareSerial
SoftwareSerial HM11(ARDUINO_SOFT_Rx,ARDUINO_SOFT_Tx);

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
  
  // setup sensors and UARTs
  sensor.begin(); // start the temperature //sensor
  Serial.begin(BAUD_RATE);
  HM11.begin(BAUD_RATE);
}


// LOOP ---------------------------------------
void loop() {
  delay(50); // make an intentional delay
   
// READING FROM PHONE
  if (HM11.available()>0) { // if there are any bytes
  
    byte receivedBytes[2] = {0, 0};
    int counter = 0;
    while (HM11.available()>0 ) { // read all bytes from HM11, but no more than 2
    
      byte nextByte = HM11.read();
      Serial.print((char)nextByte);
      
      if (counter<2) {
        receivedBytes[counter] = nextByte;      
      }
      counter = counter + 1; // increment counter
    }
    
    // here we have an array of 2 bytes, first is the command, second is the value
    byte commandByte = receivedBytes[0];
    byte valueByte = receivedBytes[1];
    
    // check through possiShield commands
    if (commandByte == COMMAND_SET_HEAT) {
      setHeat(valueByte);
    }
    else if (commandByte == COMMAND_GET_HEAT) {
      sendHeatToPhone();
    }
    else if (commandByte == COMMAND_SET_MODE) {
      setMode(valueByte);
    }
    else if (commandByte == COMMAND_GET_MODE) {
      sendModeToPhone();
    }
    else if (commandByte == COMMAND_GET_IS_CHARGING) {
      sendIsChargingToPhone();
    }
    else if (commandByte == COMMAND_GET_BATTERY_LEVEL) {
      sendBatteryLevelToPhone();
    }
    else if (commandByte == COMMAND_GET_TEMPERATURE) {
      sendTemperatureToPhone();
    }
    
  } // end of "is there any bytes availaShield" IF statement  
  
  
// READ FROM SERIAL AND TRANSMIT COMMAND TO HM11
// THIS IS FOR DEBUG THROUGH SERIAL MONITIR
// this is for writing AT commands to the serial monitor
  if (Serial.available()) {//check if there's any data sent from the local serial terminal, you can add the other applications here
    while (Serial.available() > 0) {
      char recvChar  = Serial.read();
      HM11.print(recvChar);
    }
  }
  
  // check if Shield changed charging status
  int isNowCharging = analogRead(chargePin);
  if (isNowCharging > 100) {
    if (isCharging == 0) {
      isCharging = 1;
      sendIsChargingToPhone();        
    }
  }
  else {
    if (isCharging == 1) {
      isCharging = 0;
      sendIsChargingToPhone();
    }
  }
  
  if (loopCounter == 30) { // once in 3 seconds
    loopCounter = 0; // LOOP COUNTER IS ZEROED HERE
    
    // calculate now battery level
    int nowBatteryLevel = 0;
    for (int i=0; i<30; i++) {
      nowBatteryLevel += battteryLevels[i];
    }
    nowBatteryLevel = (int)((float)nowBatteryLevel/30.);
    
    // see if we need to send it to the phone
    if (currentBatteryLevel != nowBatteryLevel) {
      currentBatteryLevel = nowBatteryLevel;
      sendBatteryLevelToPhone();
    }
    
  }
  else if (loopCounter == 15) {
    
    sensor.requestTemperatures();
    float scannedTemperature = sensor.getTempCByIndex(0);
    if (scannedTemperature != currentTemperature) {
      currentTemperature = scannedTemperature;
      sendTemperatureToPhone();
    }
  }
  
  battteryLevels[loopCounter] = analogRead(batteryPin);
  loopCounter = loopCounter + 1;  
} // end of loop


// ACTIONS ------------------------------------------------
// HEAT
void setHeat(int heat) {
  currentHeat = heat;
  analogWrite(heatPin, map(heat, 0, 100, 0, 255));
  analogWrite(logoPin, map(heat, 0, 100, 0, 255));
  sendHeatToPhone();
}

void sendHeatToPhone() {
  HM11.write((byte)COMMAND_HEAT_IS);
  HM11.write((byte)currentHeat);
}

// MODE
void setMode(int mode) {
  currentMode = mode;
  if (mode == 1) { setHeat(AUTO_MODE_HEAT_LEVEL); } // auto
  sendModeToPhone();
}

void sendModeToPhone() {
  HM11.write((byte)COMMAND_MODE_IS);
  HM11.write((byte)currentMode);
}

// BATTERY
void sendIsChargingToPhone() {
  HM11.write((byte)COMMAND_IS_CHARGING);
  HM11.write((byte)isCharging);
}
  
void sendBatteryLevelToPhone() {
  HM11.write((byte)COMMAND_BATTERY_LEVEL_IS);
  int batteryLevelToSend = currentBatteryLevel;
  if (currentBatteryLevel < 800) { batteryLevelToSend = 800; }
  if (currentBatteryLevel > 900) { batteryLevelToSend = 900; }
  HM11.write((byte) map(batteryLevelToSend, 800, 900, 0, 100));
}

// TEMPERATURE
void sendTemperatureToPhone() {
  // from -50 to +200 (0-255)
  int currentIntTemperature = (int)currentTemperature + 50;
  if (currentIntTemperature<0) { currentIntTemperature = 0;}
  if (currentIntTemperature>250) { currentIntTemperature = 250;}  

  HM11.write((byte)COMMAND_TEMPERATURE_IS);
  HM11.write((byte)currentIntTemperature);
}
