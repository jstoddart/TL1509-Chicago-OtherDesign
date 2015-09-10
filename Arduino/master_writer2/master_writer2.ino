// Wire Master Writer
// by Nicholas Zambetti <http://www.zambetti.com>

// Demonstrates use of the Wire library
// Writes data to an I2C/TWI slave device
// Refer to the "Wire Slave Receiver" example for use with this

// Created 29 March 2006

// This example code is in the public domain.


#include <Wire.h>

void setup()
{
  Wire.begin(); // join i2c bus (address optional for master)
  pinMode(13, OUTPUT);
  Serial.begin(9600);
}

byte x = 0;

void loop()
{
//  for (int i = 0; i < 2; i++){
//    Wire.beginTransmission(8+i); // transmit to device #4
//    Wire.write(0);              // sends one byte
//    Wire.endTransmission();    // stop transmitting
//    digitalWrite(13, HIGH);
//    delay(500);
//    Wire.beginTransmission(8+i); // transmit to device #4
//    Wire.write(1);              // sends one byte
//    Wire.endTransmission();    // stop transmitting
//    digitalWrite(13, LOW);
//    delay(500);
//  }

  if (Serial.available() > 0) {
    
    int i = Serial.read();
    Serial.print(i);
    
    Wire.beginTransmission(i-40); // transmit to device #4
    Wire.write(0);              // sends one byte
    Wire.endTransmission();    // stop transmitting
    digitalWrite(13, HIGH);
    delay(500);
    Wire.beginTransmission(i-40); // transmit to device #4
    Wire.write(1);              // sends one byte
    Wire.endTransmission();    // stop transmitting
    digitalWrite(13, LOW);
    delay(500);
  }

  x++;
  //delay(1000);
}
