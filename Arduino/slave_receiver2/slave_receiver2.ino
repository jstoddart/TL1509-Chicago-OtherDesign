// ///////////////////////////////////////////////
//
// Slave Receiver | The Living | 2015
//
// ///////////////////////////////////////////////

#include <Wire.h>

// //////// Constants. ////////

// I2C address of this slave Arduino.
#define SLAVE_ADDRESS 22

// Latch pin indicates when shift register should start/stop listening.
// The wire is green.
#define LATCH_PIN 4

// Clock pin indicates which output pin to associate data with.
// The wire is blue.
#define CLOCK_PIN 8

// Data pin transfers binary data. The wire is yellow.
#define DATA_PIN 7

// //////// Global variables. ////////

byte sensorReading;

// //////// Initialization. ////////

void setup() {

  // Join I2C bus.
  Wire.begin(SLAVE_ADDRESS);

  // Register event handlers for I2C communications.
  Wire.onReceive(receiveEvent);
  Wire.onRequest(requestEvent);

  // Start serial.
  Serial.begin(9600);

  // Initialize the nozzle controllers.
  initializeNozzles();
}

void initializeNozzles() {

  //Setup latch pin for Shift-Register
  pinMode(LATCH_PIN, OUTPUT);
}

// //////// Main loop. ////////

void loop() {

  // Nothing to do here.
}

// //////// Event handlers. ////////

void receiveEvent(int bytes) {

  // If a complete signal is received.
  if (Wire.available() >= 2) {

    // Assemble the signal.
    byte lowerByte = Wire.read();
    byte higherByte = Wire.read();
    short signal = (higherByte << 8) | lowerByte;

    // Print the signal to serial for debugging.
    Serial.print(signal);

    // Issue the signal to nozzle controllers.
    fireNozzles(signal);
  }
}

void requestEvent() {

  // Print debug message.
  Serial.print("request event triggered. ");

  // Alternating 0 and 1 as dummy sensor readings.
  sensorReading = (sensorReading + 1) % 2;

  // Write the sensor reading back to master via I2C.
  Wire.write(sensorReading);
}

// //////// Nozzle control. ////////

void shiftOut(byte myDataOut) {

  int pinState;

  pinMode(CLOCK_PIN, OUTPUT);
  pinMode(DATA_PIN, OUTPUT);

  digitalWrite(DATA_PIN, 0);
  digitalWrite(CLOCK_PIN, 0);

  for (int i = 7; i >= 0; i--) {

    digitalWrite(CLOCK_PIN, 0);

    if (myDataOut & (1 << i)) {
      pinState = 1;
    } else {
      pinState = 0;
    }

    digitalWrite(DATA_PIN, pinState);
    digitalWrite(CLOCK_PIN, 1);
    digitalWrite(DATA_PIN, 0);
  }

  digitalWrite(CLOCK_PIN, 0);
}

// //// Firing nozzles with a short integer signal. ////

void fireNozzles(short signal) {

  byte loByte = signal & 0xFF;
  byte hiByte = (signal & 0xFF00) >> 8;

  digitalWrite(LATCH_PIN, 0);
  shiftOut(hiByte);
  shiftOut(loByte);
  digitalWrite(LATCH_PIN, 1);
}
