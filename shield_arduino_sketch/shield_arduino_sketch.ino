/* 
SHIELD Controller v2 Frimware

Аналоговые PIN:
А0 — напряжение от аккумулятора №1
А1 — напряжение от аккумулятора №2
А2 — напряжение от аккумулятора №3
А3 — напряжение от аккумулятора №4

Входные напряжения этих пинов надо будет подбирать по результатам испытаний, когда будет скетч готов, ориентировочно:
1.8V — зарядка 0%
2.0V — зарядка 100%

Общая зарядка аккумуляторов будет считаться как среднее арифметическое 4-х значений. 
Контроль каждого аккумулятора нам необходим т.к. они разряжаются неравномерно.
А4 — сигнал "подключена зарядка" если зарядка подключена приходит напряжение 4V.

Цифровые PIN:
12 — управление логотипом
11 — управление нагревом
*/

#include <SoftwareSerial.h>
 
SoftwareSerial mySerial(0, 1);

const int CHANGING_HEAT_LEVEL = 102;
int whatWereDoingByte = 255;
int valueByte = 255;

int logo = 12;
int heat = 11;
int charge = 13; // Индикатор зарядки SHIELD от внешней сети
int incomingbyte = 0;

float battery0 = 0;
float battery1 = 0;
float battery2 = 0;
float battery3 = 0;
float charging = 0;

int currentShieldHeatValue = 0;

void setup() {
  Serial.begin(115200);
  mySerial.begin(115200);
  
  pinMode(logo, OUTPUT);
  pinMode(heat, OUTPUT);
  pinMode(charge, OUTPUT);
  digitalWrite(logo, LOW);
  digitalWrite(heat, LOW);
  digitalWrite(charge, LOW);
  
  delay(1000);
  Serial.println("SHEILD IS HERE"); 
}

void loop() {
  
  /* BATTERIES */
  battery0 = analogRead(A0);
  battery1 = analogRead(A1);
  battery2 = analogRead(A2);
  battery3 = analogRead(A3);
  
  Serial.print("BATTERY 0 VOLTAGE = ");
  Serial.println(battery0);
  Serial.print("BATTERY 1 VOLTAGE = ");
  Serial.println(battery1);
  Serial.print("BATTERY 2 VOLTAGE = ");
  Serial.println(battery2);
  Serial.print("BATTERY 3 VOLTAGE = ");
  Serial.println(battery3);

  // Если напряжение на какой-либо из батарей падает до 1.75V мы отключаем SHIELD
  if (battery0 <= 1.75)  {
   digitalWrite(heat, LOW);
   digitalWrite(logo, LOW);
   Serial.println("SHIELD IS TURNED OFF, BATTERY 0 VOLTAGE <= 1.75V");
  } else if (battery1 <= 1.75) {
   digitalWrite(heat, LOW);
   digitalWrite(logo, LOW);
   Serial.println("SHIELD IS TURNED OFF, BATTERY 1 VOLTAGE <= 1.75V");
  } else if (battery2 <= 1.75) {
   digitalWrite(heat, LOW);
   digitalWrite(logo, LOW);
   Serial.println("SHIELD IS TURNED OFF, BATTERY 2 VOLTAGE <= 1.75V");
  } else if (battery3 <= 1.75) {
   digitalWrite(heat, LOW);
   digitalWrite(logo, LOW);
   Serial.println("SHIELD IS TURNED OFF, BATTERY 3 VOLTAGE <= 1.75V");
  }
  
  /* CHARGING */
  charging = analogRead(A4);

  Serial.print("CHARGING VOLTAGE = ");
  Serial.println(charging);
  
  // Если напряжение на входе больше 0,1V - зарядное устройство подключено
  if (charging > 0.01) {
    digitalWrite(charge, HIGH);
    Serial.println("CHARGER PLUGGED IN");
  } else {
    digitalWrite(charge, LOW);
    Serial.println("CHARGER IS NOT PLUGGED");
  }
  
  delay(10000);
  
  /* BLE */
  if(mySerial.available() > 0) {

    // int currentMessagePointer = 0;
    // int whatWereDoingByte = 0;
    // int valueByte = 0;

    incomingbyte = mySerial.read();
    Serial.print("GOT BYTE: ");
    Serial.println(incomingbyte);

    if (incomingbyte == CHANGING_HEAT_LEVEL) { // what were doing byte
      whatWereDoingByte = incomingbyte;
    }
    else if (incomingbyte >= 0 && incomingbyte <= 100) { // value byte
      valueByte = incomingbyte;
    }
    else {
      valueByte = 255;        
      whatWereDoingByte = 255;
    }

    if (whatWereDoingByte != 255 && valueByte !=255) {

      // decide on what to do with the incoming data
      if (whatWereDoingByte == CHANGING_HEAT_LEVEL) {
        setHeatVelueToShield(valueByte);
      }

      valueByte = 255;        
      whatWereDoingByte = 255;
    }
  } 
}

void setHeatVelueToShield( int value ) {

  if (currentShieldHeatValue == 0 && value!=0) {
    // turning on
    digitalWrite(logo, HIGH);
    digitalWrite(heat, HIGH);
    Serial.println("SHIELD IS SWITCHING ON");
  }
  else if (currentShieldHeatValue != 0 && value == 0) {
    digitalWrite(logo, LOW);
    digitalWrite(heat, LOW);
    Serial.println("SHIELD IS SWITCHING OFF");
  }

  currentShieldHeatValue = value;
  Serial.print("SETTING VALUE TO SHIELD: ");
  Serial.println(currentShieldHeatValue);

  // here is the place to put the code that physically controls shield

}
