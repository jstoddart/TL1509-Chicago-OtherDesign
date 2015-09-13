// Wire Slave Receiver
// by Nicholas Zambetti <http://www.zambetti.com>

// Demonstrates use of the Wire library
// Receives data as an I2C/TWI slave device
// Refer to the "Wire Master Writer" example for use with this

// Created 29 March 2006

// This example code is in the public domain.


#include <Wire.h>

//bool on = true;

void setup()
{
  Wire.begin(8);                // join i2c bus with address #4
  Wire.onReceive(receiveEvent); // register event
  Serial.begin(9600);           // start serial for output
  pinMode(13, OUTPUT);
}

void loop()
{
  delay(100);
}

// function that executes whenever data is received from master
// this function is registered as an event, see setup()
void receiveEvent(int howMany)
{
  if (Wire.available() == 2) {
    byte lowerByte = Wire.read();
    byte higherByte = Wire.read();
    short signal = (higherByte << 8) | lowerByte;
    Serial.print(signal);
    byte parity = signal % 2;
    //    byte parity = 1;
    if (parity) {
      digitalWrite(13, HIGH);
    } else {
      digitalWrite(13, LOW);
    }
  }

  //  if (x == 0){
  //    digitalWrite(13, HIGH);
  //  }else{
  //  //delay(1000);
  //    digitalWrite(13, LOW);
  //  }
}