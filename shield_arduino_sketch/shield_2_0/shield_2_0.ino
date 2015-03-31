// INCLUDES
#include <SoftwareSerial.h>

/* ------------------------------------ API DEFINES ------------------------------------
The phone talks to arduino and arduino talks back to the phone by sending 1 or 2 byte long commands.
Some of the commands need an additional value byte, example - SET_HEAT_LEVEL
Some of the commands don't, example - GET_HEAT_LEVEL
*/

// Commands that the phone sends to arduino are in range [101..110]
// heat level
const int COMMAND_SET_HEAT = 101; // Needs an additional value byte, indicating heat level. Range is [0..100]
const int COMMAND_GET_HEAT = 102;
// mode
const int COMMAND_SET_MODE = 103; // Needs an additional value byte, indicating mode. 0 - manual, 1 - auto
const int COMMAND_GET_MODE = 104;
// battery level and chargin' indication
const int COMMAND_GET_IS_CHARGING = 105;
const int COMMAND_GET_BATTERY_LEVEL = 106;

// Commands that arduino sends to the phone are in range [111..120]
// heat level
const int COMMAND_HEAT_IS = 111; // Sending back current heat level
// mode
const int COMMAND_MODE_IS = 112; // Sending back current mode
// battery level and chargin'
const int COMMAND_IS_CHARGING = 113; // Sending back charging status
const int COMMAND_BATTERY_LEVEL_IS = 114; // Sending back battery level

// ARDUINO PROPERTIES
SoftwareSerial Shield(0, 1);         // Our Shield's UART, (Rx, Tx)
int currentHeat, heatSetByUser = 0;  // Range is [0..100]
int currentMode, modeSetByUser = 0;  // 0 - manual, 1 - auto
int isCharging = 0;                  // 0 - not charging, 1 - charging
int currentBatteryLevel = 0;         // current battery level of Shield

// PIN DEFINES
int logoPin = 9;
int heatPin = 10;
int chargePin = 10;

// OTHERS
int AUTO_MODE_HEAT_LEVEL = 50;
int loopCounter = 0;

/* ------------------------------------ CODE ------------------------------------ */
// SETUP
void setup() {
  // start serials
  Serial.begin(115200);  
  Shield.begin(115200);
  // setup pins
  pinMode(logoPin, OUTPUT);
  pinMode(heatPin, OUTPUT);
  pinMode(chargePin, INPUT);
  // default the output
  digitalWrite(logoPin, LOW);
  digitalWrite(heatPin, LOW);
}

// LOOP
void loop() {  
  
  delay(100); // make an intentional delay
  
  // Shield.availaShield() returns count of bytes availaShield through Shields UART
  // so we read all availaShield bytes, of which there should be 2 or 1
  if (Shield.available()>0) { // if there are any bytes availaShield
  
    byte receivedBytes[2] = {0, 0};
    int counter = 0;
    while (Shield.available()>0 ) { // read all availaShield bytes, but no more than 2
      if (counter<2) {
        receivedBytes[counter] = Shield.read();      
      }
      else {
        // just flush the unneeded byte
        byte unneededByte = Shield.read();
      }
      counter = counter + 1; // increment counter
    }
    
    // here we have an array of 2 bytes, first is the command, second is the value
    byte commandByte = receivedBytes[0];
    byte valueByte = receivedBytes[1];
    
    // check through possiShield commands
    if (commandByte == COMMAND_SET_HEAT) {
      heatSetByUser = valueByte;
      setHeatValueToShield(heatSetByUser);
    }
    else if (commandByte == COMMAND_GET_HEAT) {
      sendCurrentHeatLevelToPhone();
    }
    else if (commandByte == COMMAND_SET_MODE) {
      modeSetByUser = valueByte;
      setModeToShield(modeSetByUser);
    }
    else if (commandByte == COMMAND_GET_MODE) {
      sendCurrentModeToPhone();
    }
    else if (commandByte == COMMAND_GET_IS_CHARGING) {
      sendIsChargingToPhone();
    }
    else if (commandByte == COMMAND_GET_BATTERY_LEVEL) {
      sendCurrentBatteryLevelToPhone();
    }
    
  } // end of "is there any bytes availaShield" IF statement
  
  // charging and battery level code should only run once a second, not every 100ms loop    
  if (loopCounter == 10) {
    loopCounter = 0; 
    
    // TODO
    // check if Shield changed charging status
    // check if Shield changed battery level
  }

  loopCounter = loopCounter + 1;    
      
} // end of loop


// ACTIONS
// HEAT
void setHeatValueToShield(int value) {
  currentHeat = value;
  // just write the appropriate value to heat and logo pins
  analogWrite(heatPin, map(value, 0, 100, 0, 255));
  analogWrite(logoPin, map(value, 0, 100, 0, 255));
}

void sendCurrentHeatLevelToPhone() {
  byte bytesToSend[2] = {COMMAND_HEAT_IS, currentHeat};
  Shield.write(bytesToSend, 2);
}

// MODE
void setModeToShield(int mode) {
  currentMode = mode;
  if (mode == 0) { // manual
    setHeatValueToShield(heatSetByUser);
  }
  else if (mode == 1) { // auto
    setHeatValueToShield(AUTO_MODE_HEAT_LEVEL);
  }
}

void sendCurrentModeToPhone() {
  byte bytesToSend[2] = {COMMAND_MODE_IS, currentMode};
  Shield.write(bytesToSend, 2);
}

// BATTERY
void sendIsChargingToPhone() {
  byte bytesToSend[2] = {COMMAND_IS_CHARGING, isCharging};
  Shield.write(bytesToSend, 2);
}
  
void sendCurrentBatteryLevelToPhone() {
  byte bytesToSend [2] = {COMMAND_BATTERY_LEVEL_IS, currentBatteryLevel};
  Shield.write(bytesToSend, 2);
}
