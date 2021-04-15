#include "SPI.h"


int SS_pin = 10;


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
