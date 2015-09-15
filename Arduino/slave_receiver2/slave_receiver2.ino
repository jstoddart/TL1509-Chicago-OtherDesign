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
// Pins for IR sensor.
#define IR_LEFT_PIN 2
#define IR_RIGHT_PIN 3
// Pin for built-in LED.
#define LED_PIN 13

// //////// Global variables. ////////

// IR sensor reading.
byte irSensorReading = 0;

// //////// Initialization. ////////

void setup() {

  // Join I2C bus.
  Wire.begin(SLAVE_ADDRESS);

  // Register event handlers for I2C communications.
  Wire.onReceive(receiveEvent);
  Wire.onRequest(requestEvent);

  // Start serial.
  Serial.begin(9600);

  initializeNozzles();
  initializeSensor();

  pinMode(LED_PIN, OUTPUT);
}

void initializeNozzles() {

  pinMode(LATCH_PIN, OUTPUT);
}

void initializeSensor() {

  pinMode(IR_LEFT_PIN, INPUT);
  pinMode(IR_RIGHT_PIN, INPUT);
}

// //////// Main loop. ////////

void loop() {

  readIrSensor();
}

// //////// Event handlers. ////////

void receiveEvent(int bytes) {

  // If a complete signal is received.
  if (Wire.available() >= 2) {

    // Assemble the signal.
    byte loByte = Wire.read();
    byte hiByte = Wire.read();
    unsigned short signal = (hiByte << 8) | loByte;

    // Print the signal to serial for debugging.
    Serial.print("[SIGNAL FROM MASTER] ");
    Serial.print(hiByte, BIN);
    Serial.print("-");
    Serial.print(loByte, BIN);
    Serial.print("-");
    Serial.println(signal, BIN);

    // Issue the signal to nozzle controllers.
    fireNozzles(signal);
  }
}

void requestEvent() {

  // Print debug message.
  Serial.println("[REQUEST]");

  // Write the IR sensor reading back to master via I2C.
  Wire.write(irSensorReading);

  // Reset sensor reading so that the next trigger could be detected.
  irSensorReading = 0;
  // For debugging, turn off LED.
  digitalWrite(LED_PIN, 0);
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

// //////// Sensor reading. ////////

void readIrSensor() {

//  Serial.println("[IR SENSOR]");

  // Get the latest reading from the IR sensor.
  int currentSensorReading =
    digitalRead(IR_LEFT_PIN) | digitalRead(IR_RIGHT_PIN);

  // If the sensor is blocked, update the reading.
  if (currentSensorReading) {
    irSensorReading = 1;
    // For debugging, also lit up the LED.
    digitalWrite(LED_PIN, 1);
  }
}
