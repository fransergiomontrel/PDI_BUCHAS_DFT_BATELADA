#include "SPI.h"
// Para arquino UNO
// SCLK = 13
// MISO = 12
// MOSI = 11

// Para arquino MEGA
// SCLK = 52
// MISO = 50
// MOSI = 51

int SS_pin = 10;  // <- Arduino UNO (para o MEGA é o pino 53)

void setup() {
  pinMode (SS_pin, OUTPUT);
  digitalWrite(SS_pin, HIGH);
  SPI.begin();
}

void send(unsigned char value){
  SPI.beginTransaction(SPISettings(1000000, MSBFIRST, SPI_MODE0));
  digitalWrite(SS_pin, LOW);
  SPI.transfer(value);
  digitalWrite(SS_pin, HIGH);
  SPI.endTransaction();
}

int x =0;
void loop() {
  send(x);
  x++;
}
