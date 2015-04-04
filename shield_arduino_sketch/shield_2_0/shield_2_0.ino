// VERSION 0.0.3

// INCLUDES
#include <OneWire.h>
#include <DallasTemperature.h>

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
int currentBatteryLevel = 0;         // current battery level of Shield
float currentTemperature = 0;        // last scanned temperature from //sensor

// PIN DEFINES
int logoPin = 9;
int heatPin = 10;
int chargePin = A2;
int temperaturePin = 3;

// TEMPERATURE sensor SHIT
OneWire oneWire(temperaturePin);
DallasTemperature sensor(&oneWire);

// OTHERS
int AUTO_MODE_HEAT_LEVEL = 50;
int loopCounter = 0;

/* ------------------------------------ CODE ------------------------------------ */
// SETUP
void setup() {
  sensor.begin(); // start the temperature //sensor
  Serial.begin(115200); // start serial
  // setup pins
  pinMode(logoPin, OUTPUT);
  pinMode(heatPin, OUTPUT);
  pinMode(chargePin, INPUT);
  
  // default the output
  digitalWrite(logoPin, LOW);
  digitalWrite(heatPin, LOW);
}

// LOOP ---------------------------------------
void loop() {
  delay(100); // make an intentional delay
  
  // Shield.availaShield() returns count of bytes availaShield through Shields UART
  // so we read all availaShield bytes, of which there should be 2 or 1
  if (Serial.available()>0) { // if there are any bytes availaShield
  
    byte receivedBytes[2] = {0, 0};
    int counter = 0;
    while (Serial.available()>0 ) { // read all availaShield bytes, but no more than 2
      if (counter<2) {
        receivedBytes[counter] = Serial.read();      
      }
      else {
        // just flush the unneeded byte
        byte unneededByte = Serial.read();
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
  
  // check if Shield changed charging status
  int isNowCharging = analogRead(chargePin);
  if (isNowCharging > 0) { // this is happening when you send current to A2 hell knows why
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

  if (loopCounter == 30) { // once every 3 seconds
    loopCounter = 0; 
    
    sensor.requestTemperatures();
    float scannedTemperature = sensor.getTempCByIndex(0);
    if (scannedTemperature != currentTemperature) {
      currentTemperature = scannedTemperature;
      sendTemperatureToPhone();
    }
         
    // TODO
    // check if Shield changed battery level
  }
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
  Serial.println((byte)COMMAND_HEAT_IS);
  Serial.println((byte)currentHeat);
}

// MODE
void setMode(int mode) {
  currentMode = mode;
  if (mode == 1) { setHeat(AUTO_MODE_HEAT_LEVEL); } // auto
  sendModeToPhone();
}

void sendModeToPhone() {
  Serial.println((byte)COMMAND_MODE_IS);
  Serial.println((byte)currentMode);
}

// BATTERY
void sendIsChargingToPhone() {
  Serial.println((byte)COMMAND_IS_CHARGING);
  Serial.println((byte)isCharging);
}
  
void sendBatteryLevelToPhone() {

}

// TEMPERATURE
void sendTemperatureToPhone() {
  // from -40 to +60 (0-100)
  int currentIntTemperature = (int)currentTemperature + 40;
  if (currentIntTemperature<0) { currentIntTemperature = 0;}
  if (currentIntTemperature>100) { currentIntTemperature = 100;}  

  Serial.println((byte)COMMAND_TEMPERATURE_IS);
  Serial.println((byte)currentIntTemperature);
}
