#include <SoftwareSerial.h>

int logo = 9;
int heat = 10;

SoftwareSerial BLE(0, 1);

const int CHANGING_HEAT_LEVEL = 101;

int whatWereDoingByte = 255;
int valueByte = 255;

void setup() {
  Serial.begin(115200);  
  BLE.begin(115200);
}

void loop() {  
  
  char recvChar;
  while (BLE.available()>0) {
    
    if( BLE.available() ){ //check if there's any data sent from the remote BLE shield
      byte recvByte = (byte)BLE.read();
      
      if (recvByte == CHANGING_HEAT_LEVEL) { // changing heat level byte
        whatWereDoingByte = recvByte;
      }
      else if (recvByte >= 0 && recvByte <= 100) { // value byte
        valueByte = recvByte;
      }
      else {
        valueByte = 255;        
        whatWereDoingByte = 255;
      }      
    }
  }
  
  // check everything we got
  if (whatWereDoingByte != 255 && valueByte !=255) {

    // decide on what to do with the incoming data
    if (whatWereDoingByte == CHANGING_HEAT_LEVEL) {
      setHeatVelueToShield(valueByte);
    }

    valueByte = 255;        
    whatWereDoingByte = 255;
  }
  
}

void setHeatVelueToShield( int value ) {
  analogWrite(heat, map(value, 0, 100, 0, 255));
  analogWrite(logo, map(value, 0, 100, 0, 255));
}
