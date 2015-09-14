// /////////////////////////////////////
//
// Master Dispatcher | The Living | 2015
//
// /////////////////////////////////////


#include <Wire.h>

// //////// Constants. ////////

// The number of tanks in the system.
#define N_TANKS 22
// The start of the slaves' sequential I2C addresses.
#define SLAVE_ADDRESS_START 19
// A trigger signal that makes master Arduino to request sensor data from slaves.
#define TRIGGER_SIGNAL_REQUEST_SENSOR_DATA 42
// Time to keep nozzles on (in milliseconds).
#define NOZZLE_DELAY 200

// //////// Global varaibles. ////////

// Stores signals received from Raspberry Pi to send to slaves.
unsigned short signals[N_TANKS];
// Sensor readings retrieved from slaves.
byte readings[N_TANKS];

// //////// Initialization. ////////

void setup() {

  Wire.begin(); // Join i2c bus (address optional for master).
  Serial.begin(9600);
}

// //////// Main loop. ////////

void loop() {

  // Request sensor readings from individual slaves.
  requestSensorReadings();

  // Communicate the sensor readings back to Raspberry Pi
  // so the latter could generate signals for slaves to act on.
  sendSensorData();

  // Dispatch the signals received from Raspberry Pi to slaves
  // for the to execute.
  handleSignals();

  // Wait for a trigger signal from Pi to continue requesting
  // sensor readings.
  waitToRequestSensorReadings();
}

void requestSensorReadings() {

  for (int tank = 0; tank < N_TANKS; ++tank) {

    // Request a 1-byte sensor reading from the tank.
    int device = getDevice(tank);
    Wire.requestFrom(device, 1);

    // Debugging message delimiter (111) to be displayed on Pi.
//    Serial.print('o');

    if(Wire.available()) {

      // Store the sensor reading into the corresponding entry.
      readings[tank] = Wire.read(); 

      // Write back to Pi for debugging.
      // Serial.write(readings[tank]);
    }
  }
}

void sendSensorData() {

  for (int tank = 0; tank < N_TANKS; ++tank) {
    Serial.write(readings[tank]);
  }
}

void handleSignals() {

  // 0 if we are expecting the lower byte of a signal. 1 otherwise.
  byte gotLowerByte = 0;
  // The lower byte of the current signal being received.
  byte lowerByte = 0;
  // Index of the next entry to store the signal to.
  int signalIndex = 0;

  // Collect signals from  Pi for all tank.
  while (signalIndex < N_TANKS) {

    if (Serial.available() > 0) {

      // Read data from Pi.
      byte data = Serial.read();

      if (gotLowerByte) {    // This is the higher byte of the signal.

        // Next time we'll be expecting a lower byte.
        gotLowerByte = 0;

        // Assemble the signal from the two bytes.
        byte higherByte = data;
        unsigned short signal = higherByte << 8 | lowerByte;

        // Write the signal back to Pi for debugging.
        // Serial.write(signal);

        // Store the signal and increment the index.
        signals[signalIndex] = signal;
        ++signalIndex;

      } else {    // This is the lower byte of the signal.

        // Now we got the lower byte, store it for assembling a signal later.
        gotLowerByte = 1;
        lowerByte = data;
      }
    }
  }

  // After receiving all the signals, fire them to corresponding tanks.
  fireSignals();

  // Debugging message delimiter (112) to be displayed on Pi.
  // Serial.write('p');
}

void waitToRequestSensorReadings() {

  // Block until the Pi sends a trigger signal to continue requesting
  // sensor readings.
  while(1) {
    if (Serial.available() > 0) {
      byte data = Serial.read();
      if (data == TRIGGER_SIGNAL_REQUEST_SENSOR_DATA) break;
    }
  }
}

// //////// Utility functions. ////////

void fireSignals() {

  for (int tank = 0; tank < N_TANKS; ++tank) {

    // Get the device address from tank number.
    int device = getDevice(tank);

    Wire.beginTransmission(device);

    // Break down the signal into two bytes and send them.
    unsigned short signal = signals[tank];
    byte loByte = signal & 0xFF;
    byte hiByte = (signal & 0xFF00) >> 8;
    Wire.write(loByte);
    Wire.write(hiByte);
    
    Wire.endTransmission();
  }

  // Keep the nozzles on for a little while.
  delay(NOZZLE_DELAY);

  // Turn off all nozzles.
  for (int tank = 0; tank < N_TANKS; ++tank) {

    // Get the device address from tank number.
    int device = getDevice(tank);

    Wire.beginTransmission(device);

    // Break down the signal into two bytes and send them.
    unsigned short signal = 0;
    byte loByte = signal & 0xFF;
    byte hiByte = (signal & 0xFF00) >> 8;
    Wire.write(loByte);
    Wire.write(hiByte);

    Wire.endTransmission();
  }
}

int getDevice(int tank) {

  // The I2C addresses of the slaves are arranged sequentially starting from
  // `SLAVE_ADDRESS_START`.
  return tank + SLAVE_ADDRESS_START;
}
