#include <Wire.h>              
#include <Adafruit_BMP280.h>    
#include <TinyGPS++.h>        
#include <SoftwareSerial.h>    


Adafruit_BMP280 bmp;          
TinyGPSPlus gps;              
SoftwareSerial ss(4, 3);


const int pinHumedad = A0;    


// --- AJUSTE DE HUMEDAD ---
// Subimos a 1010 para que el 76% de antes baje al entorno del 65%
int valorSeco = 1010;  
int valorHumedo = 120;


// --- AJUSTE DE ALTITUD ---
// Si marca muy bajo, subimos este valor. 1017.0 debería darte esos ~30m
float qnhLocal = 1017.0;


void setup() {
  Serial.begin(9600);
  ss.begin(9600);
 
  // Inicialización robusta del sensor
  if (!bmp.begin(0x76)) {
    bmp.begin(0x77);
  }


  bmp.setSampling(Adafruit_BMP280::MODE_NORMAL, Adafruit_BMP280::SAMPLING_X2,
                  Adafruit_BMP280::SAMPLING_X16, Adafruit_BMP280::FILTER_X16,
                  Adafruit_BMP280::STANDBY_MS_500);
}


void loop() {
  while (ss.available() > 0) gps.encode(ss.read());


  static unsigned long tAnterior = 0;
  if (millis() - tAnterior > 1000) {
    int bruto = analogRead(pinHumedad);
    int hum = map(bruto, valorSeco, valorHumedo, 0, 100);
    hum = constrain(hum, 0, 100);


    // Lectura de sensores con seguridad para evitar NaN
    float presRaw = bmp.readPressure();
    float pres = (presRaw > 0) ? presRaw / 100.0 : 1013.25;
    float temp = bmp.readTemperature();
    float alt = bmp.readAltitude(qnhLocal);


    // Formato de salida para Processing
    Serial.print("NanoSkyLab,");
    if (gps.date.isValid()) {
      Serial.print(gps.date.day()); Serial.print("/");
      Serial.print(gps.date.month()); Serial.print("/");
      Serial.print(gps.date.year());
    } else { Serial.print("22/04/2026"); }
   
    Serial.print(","); Serial.print(hum);  
    Serial.print(","); Serial.print(pres);  
    Serial.print(","); Serial.print(temp);  
   
    if (gps.location.isValid()) {
      Serial.print(","); Serial.print(gps.location.lat(), 6);
      Serial.print(","); Serial.print(gps.location.lng(), 6);
    } else {
      Serial.print(",0.0,0.0");
    }
   
    Serial.print(","); Serial.println(alt);


    tAnterior = millis();
  }
}
