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
 А6 — сигнал "подключена зарядка" если зарядка подключена приходит напряжение 4V.
 
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
float batteryAverage = 0;
int batteryLevel = 0;
float charging = 0;

const float battery0coeff = 0.00785567010309;
const float battery1coeff = 0.00372434017595;
const float battery2coeff = 0.00374389051808;
const float battery3coeff = 0.00525555555556;
const float BATTERY_MINIMUM_V = 3.5;

int battery_levels_in_time[1000];
int batteryCounter = 0;

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


  Serial.println("SHEILD IS HERE"); 
}

void loop() {

  /* BATTERIES 
   
   BATTERY 0 VOLTAGE
   485.00  3,810  0.00785567010309
   
   BATTERY 1 VOLTAGE
   1023.00  3.810  0.00372434017595
   
   BATTERY 2 VOLTAGE
   1023.00  3.830  0.00374389051808
   
   BATTERY 3 VOLTAGE 
   720.00  3.784 0.00525555555556
   
   */
  battery0 = analogRead(A0) * battery0coeff;
  battery1 = analogRead(A1) * battery1coeff;
  battery2 = analogRead(A2) * battery2coeff;
  battery3 = analogRead(A3) * battery3coeff;

  batteryAverage = (battery0 + battery1 + battery2 + battery3) / 4;
  batteryLevel = (batteryAverage - BATTERY_MINIMUM_V) * 2 * 100;



  if (batteryCounter > 999) {
    
    batteryCounter = 0; 

    int batteryAverageOverTime = 0;
    for (int i = 0; i < 1000; i++) {
      batteryAverageOverTime += battery_levels_in_time[i];
    }
    batteryAverageOverTime = batteryAverageOverTime / 1000;

    Serial.print("BATTERIES CHARGE PERCENT = ");
    Serial.println(batteryLevel);



//    if (battery0 <= 3.5)  {
//      digitalWrite(heat, LOW);
//      digitalWrite(logo, LOW);
//      Serial.println("SHIELD IS TURNED OFF, BATTERY 0 VOLTAGE <= 1.75V");
//    } 
//    else if (battery1 <= 3.5) {
//      digitalWrite(heat, LOW);
//      digitalWrite(logo, LOW);
//      Serial.println("SHIELD IS TURNED OFF, BATTERY 1 VOLTAGE <= 1.75V");
//    } 
//    else if (battery2 <= 3.5) {
//      digitalWrite(heat, LOW);
//      digitalWrite(logo, LOW);
//      Serial.println("SHIELD IS TURNED OFF, BATTERY 2 VOLTAGE <= 1.75V");
//    } 
//    else if (battery3 <= 3.5) {
//      digitalWrite(heat, LOW);
//      digitalWrite(logo, LOW);
//      Serial.println("SHIELD IS TURNED OFF, BATTERY 3 VOLTAGE <= 1.75V");
//    }
  }

  battery_levels_in_time[batteryCounter] = batteryLevel;
  batteryCounter++;


  //  Serial.print("BATTERY 0 VOLTAGE = ");
  //  Serial.println(battery0);
  //  Serial.print("BATTERY 1 VOLTAGE = ");
  //  Serial.println(battery1);
  //  Serial.print("BATTERY 2 VOLTAGE = ");
  //  Serial.println(battery2);
  //  Serial.print("BATTERY 3 VOLTAGE = ");
  //  Serial.println(battery3);

  // Если напряжение на какой-либо из батарей падает до 1.75V мы отключаем SHIELD


  /* CHARGING */
  charging = analogRead(A6);

//  Serial.print("CHARGING VOLTAGE = ");
//  Serial.println(charging);

  // Если напряжение на входе больше 0,1V - зарядное устройство подключено
  //  if (charging > 0) {
  //    digitalWrite(charge, HIGH);
  //    Serial.println("CHARGER PLUGGED IN");
  //  } else {
  //    digitalWrite(charge, LOW);
  //    Serial.println("CHARGER IS NOT PLUGGED");
  //  }
  //  delay(500);



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

