// ///////////////////////////////////////////////
//
// p2ma (Pi To Master Arduino) | The Living | 2015
//
// ///////////////////////////////////////////////

import processing.serial.*;

final int N_SLAVES = 2;

// Serial port connecting master Arduino.
Serial masterPort;

// The signal arrays to distribute to slave Arduinos.
short[] signals;

void setup() {

  // Initialize the signal arrays to distribute to slave Arduinos.
  signals = new short[N_SLAVES];

  // Set up serial port.
  String portName = Serial.list()[0];
  masterPort = new Serial(this, portName, 9600);

  // The delay is necessary to avoid losing data at the beginning
  // of transmission.
  delay(3000);
}

void settings() {

  // We don't really need this window.
  size(200, 200);
}

void draw() {

  for (int i = 0; i < signals.length; ++i) {

    short signal = signals[i];
    
    // Delay so the LED pattern is visible.
    delay(300);

    // Write the low and high byte of each short-integer signal
    // to master port.
    masterPort.write((byte)(signal & 0xFF));
    masterPort.write((byte)((signal & 0xFF00) >> 8));
    
    // Increment the signal to make it a counter.
    ++signals[i];
  }
}