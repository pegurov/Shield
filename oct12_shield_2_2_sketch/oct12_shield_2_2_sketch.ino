#include <SoftwareSerial.h>   // Модуль для работы с Serial

SoftwareSerial mySerial(0, 1);

/* 
 SHIELD Controller v2.1 Frimware
 
 Аналоговые PIN:
 А0 — напряжение заряда аккумулятора №1
 А1 — напряжение заряда аккумулятора №2
 А2 — напряжение заряда аккумулятора №3
 А3 — напряжение заряда аккумулятора №4
 
 Входные напряжение этих пинов надо будет подбирать по результатам испытаний, когда будет скетч готов, ориентировочно:
 3.6V — зарядка 0%
 4.0V — зарядка 100%
 
 Общая зарядка аккумуляторов будет считаться как среднее арифметическое 4-х значений. А контроль каждого аккумулятора нам необходим т.к. они разряжаются неравномерно.
 А4 — сигнал "подключена зарядка" если зарядка подключена приходит напряжение (4V, если не подключена, то напряжение на входе "0").
 
 Цифровые PIN:
 10 — управление логотипом
 12 — управление нагревом
 */

// Объявляем переменные
const int CHANGING_HEAT_LEVEL = 102;

int whatWereDoingByte = 255;
int valueByte = 255;

int logo = 10; // Логотип
int heat = 12; // Нагревательные элементы
int charge = 13; // Индикатор зарядки SHIELD от внешней сети
int incomingbyte = 0; 
int c = 1;

const int Battery0 = A0; // Контроль батареи 0 
const int Battery1 = A1; // Контроль батареи 1
const int Battery2 = A2; // Контроль батареи 2
const int Battery3 = A3; // Контроль батареи 3
const int Charging = A4; // Контроль зарядки от внешней сети

int  Battery0_Value = 0; // Сначала всё ноль
int  Battery1_Value = 0;
int  Battery2_Value = 0;
int  Battery3_Value = 0;
int  Charging_Value = 0;

float Battery0_Voltage = 0; // Напряжение ноль
float Battery1_Voltage = 0;
float Battery2_Voltage = 0;
float Battery3_Voltage = 0;
float Charging_Voltage = 0;

const float Battery_Coefficient = .004883; // 5V делим на 1024 = 0.00488443 коэффициент перевода, надо будет подбирать
const float Charging_Coefficient = .007812; // 8V делим на 1024 = 0.007812 коэффициент перевода, надо будет подбирать

// Расчёт делителя напряжения, коэффицинты надо будет подбирать
const float R1 = 2; // 2 мОм
const float R2 = 1; // 1 мОм
const float R3 = 4; // 4 кОм
const float R4 = 1; // 1 кОм

// Коэффициент для расчёта напряжения на входе делителя
const float Battery_Coefficient_Ratio = ((R1 + R2) / R2);
const float Charging_Coefficient_Ratio = ((R3 + R4) / R4);

// Коэффициент перевода имерений в напряжение
const float Battery_Ratio = Battery_Coefficient * Battery_Coefficient_Ratio;
const float Charging_Ratio = Charging_Coefficient * Charging_Coefficient_Ratio;

// Инициализация переменных
void setup() {

  Serial.begin(115200);
  mySerial.begin(115200);
  pinMode(logo, OUTPUT);
  pinMode(heat, OUTPUT);
  pinMode(charge, OUTPUT);
  digitalWrite(logo, LOW);
  digitalWrite(heat, LOW);
  digitalWrite(charge, LOW);
  delay(2000);
  Serial.println("SHEILD IS HERE"); 
}

// Основной цикл программы
void loop() {

  /* BATTERIES
   Battery0_Value = analogRead(Battery0);
   Battery1_Value = analogRead(Battery1);
   Battery2_Value = analogRead(Battery2);
   Battery3_Value = analogRead(Battery3);
   
   // Расчёт напряжения в вольтах
   Battery0_Voltage = Battery0_Value*Battery_Ratio;
   Battery1_Voltage = Battery1_Value*Battery_Ratio;
   Battery2_Voltage = Battery2_Value*Battery_Ratio;
   Battery3_Voltage = Battery3_Value*Battery_Ratio;
   
   // Выводим напряжение батарей в консоль
   Serial.print("BATTERY 0 VOLTAGE = ");
   Serial.println(Battery0_Voltage);
   Serial.print("BATTERY 1 VOLTAGE = ");
   Serial.println(Battery1_Voltage);
   Serial.print("BATTERY 2 VOLTAGE = ");
   Serial.println(Battery2_Voltage);
   Serial.print("BATTERY 3 VOLTAGE = ");
   Serial.println(Battery3_Voltage);
   
   // Если напряжение на какой-либо из батарей падает до 3.55 V мы отключаем нагрев
   if (Battery0_Voltage <= 3.55) {
   digitalWrite(heat, LOW);
   Serial.println("SHIELD IS TURNED OFF, BATTERY 0 VOLTAGE <= 3.55 V");
   } else if (Battery1_Voltage <= 3.55) {
   digitalWrite(heat, LOW);
   Serial.println("SHIELD IS TURNED OFF, BATTERY 1 VOLTAGE <= 3.55 V");
   } else if (Battery2_Voltage <= 3.55) {
   digitalWrite(heat, LOW);
   Serial.println("SHIELD IS TURNED OFF, BATTERY 2 VOLTAGE <= 3.55 V");
   } else if (Battery3_Voltage <= 3.55) {
   digitalWrite(heat, LOW);
   Serial.println("SHIELD IS TURNED OFF, BATTERY 3 VOLTAGE <= 3.55 V ");
   } */

  /* CHARGING
   Charging_Value = analogRead(Charging);
   
   // Расчёт в вольтах
   Charging_Voltage = Charging_Value*Charging_Ratio;
   Serial.print("CHARGING VOLTAGE = ");
   Serial.println(Charging_Voltage);
   
   
   // Если напряжение на входе меньше 5V - зарядное устройство не подключено
   if (Charging_Voltage < 5) {
   digitalWrite(charge, LOW);
   } else {
   digitalWrite(charge, HIGH);
   } */


  /* TWIX
   delay(10000); */

  /* SWITCHING HANDMODE
   if (Serial.available() > 0){
   incomingbyte = Serial.read();
   if (incomingbyte == '1') {
   digitalWrite(logo, HIGH);
   digitalWrite(heat, HIGH);
   Serial.println("SHIELD IS TURNED ON");
   } else {
   digitalWrite(logo, LOW);
   digitalWrite(heat, LOW);
   Serial.println("SHIELD IS SWITCHED OFF");
   }
   } */

  /* SWITCHING BLE */
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

int currentShieldHeatValue = 0;

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

  //    here is the place to put the code that physically controls shield

}

