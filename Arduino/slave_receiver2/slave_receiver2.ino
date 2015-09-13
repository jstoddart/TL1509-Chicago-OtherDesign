// ///////////////////////////////////////////////
//
// Slave Receiver | The Living | 2015
//
// ///////////////////////////////////////////////

#include <Wire.h>

void setup() {

  Wire.begin(8);                // join i2c bus with address #4
  Wire.onReceive(receiveEvent); // register event
  Serial.begin(9600);           // start serial for output
  pinMode(13, OUTPUT);
  initializeNozzles();
}

void loop() {

  // Nothing to do here.
}

void receiveEvent(int howMany) {

  // If a complete signal is received.
  if (Wire.available() == 2) {

    // Assemble the signal.
    byte lowerByte = Wire.read();
    byte higherByte = Wire.read();
    short signal = (higherByte << 8) | lowerByte;

    Serial.print(signal);

    // Issue the signal to nozzle controllers.
    fireNozzles(signal);
  }
}

// //////// Nozzle control. ////////

// //// From Jim's utility library. ////

// Latch pin indicates when shift register should start/stop listening.
const int LATCH_PIN = 8;
// Clock pin indicates which output pin to associate data with.
const int CLOCK_PIN = 12;
// Data pin transfers binary data.
const int DATA_PIN = 11;

void shiftOut(int myDataPin, int myClockPin, byte myDataOut) {
  int i = 0;
  int pinState;
  pinMode(myClockPin, OUTPUT);
  pinMode(myDataPin, OUTPUT);

  //clear
  digitalWrite(myDataPin, 0);
  digitalWrite(myClockPin, 0);

  for (i = 7; i >= 0; i--) {
    digitalWrite(myClockPin, 0);

    if ( myDataOut & (1 << i) ) {
      pinState = 1;
    } else {
      pinState = 0;
    }

    //set pin to pinState
    digitalWrite(myDataPin, pinState);
    //register shift to clock
    digitalWrite(myClockPin, 1);
    //clear data pin
    digitalWrite(myDataPin, 0);
  }

  //stop shifting
  digitalWrite(myClockPin, 0);
}

// //// Nozzle initialization. ////

void initializeNozzles() {

  //Setup latch pin for Shift-Register
  pinMode(LATCH_PIN, OUTPUT);
}

// //// Firing nozzles with a short integer signal. ////

void fireNozzles(short signal) {

  byte dataLow = signal & 0xFF;
  byte dataHigh = (signal & 0xFF00) >> 8;

  digitalWrite(LATCH_PIN, 0);
  shiftOut(DATA_PIN, CLOCK_PIN, dataHigh);
  shiftOut(DATA_PIN, CLOCK_PIN, dataLow);
  digitalWrite(LATCH_PIN, 1);
}
