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

//byte x = 0;

byte gotLowerByte = 0;
byte lowerByte = 0;

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

  //  if (Serial.available() > 0) {
  //
  //    int i = Serial.read();
  //    Serial.print(i);
  //
  //    Wire.beginTransmission(i+8); // transmit to device #4
  //    Wire.write(0);              // sends one byte
  //    Wire.endTransmission();    // stop transmitting
  //    digitalWrite(13, HIGH);
  //    delay(500);
  //    Wire.beginTransmission(i+8); // transmit to device #4
  //    Wire.write(1);              // sends one byte
  //    Wire.endTransmission();    // stop transmitting
  //    digitalWrite(13, LOW);
  //    delay(500);
  //  }

  //  x++;
  //delay(1000);

  if (Serial.available() > 0) {

    byte data = Serial.read();

    if (gotLowerByte) {

      gotLowerByte = 0;
      byte higherByte = data;
      unsigned short signal = higherByte << 8 | lowerByte;
      handleSignal(signal);

    } else {

      gotLowerByte = 1;
      lowerByte = data;
    }
  }
}

#define N_TANKS 2

int signalIndex = 0;
unsigned short signals[N_TANKS];

void handleSignal(unsigned short signal) {

  storeSignal(signal);
  Serial.print(signal);
  Serial.print('o');

  if (signalIndex == N_TANKS) {
    fireSignals();
    signalIndex = 0;
  }
}

void storeSignal(unsigned short signal) {
  signals[signalIndex] = signal;
  ++signalIndex;
}

void fireSignals() {

  for (int tank = 0; tank < N_TANKS; ++tank) {
    
    unsigned short signal = signals[tank];
    int deviceId = tank + 8;
    Wire.beginTransmission(deviceId);
    byte lowerByte = signal & 0xFF;
    byte higherByte = (signal & 0xFF00) >> 8;
    Wire.write(lowerByte);
    Wire.write(higherByte);
    Wire.endTransmission();    // stop transmitting

    // A quick blink for each signal.
    digitalWrite(13, HIGH);
    delay(200);
    digitalWrite(13, LOW);
    delay(200);
  }
  
  // A longer lighting after all signals were sent.
  digitalWrite(13, HIGH);
  delay(1000);
  digitalWrite(13, LOW);
  delay(1000);
}

