// ///////////////////////////////////////////////
//
// Master dispatcher. | The Living | 2015
//
// ///////////////////////////////////////////////


#include <Wire.h>

#define N_TANKS 2

int signalIndex = 0;
unsigned short signals[N_TANKS];

void setup() {

  Wire.begin(); // Join i2c bus (address optional for master).
  pinMode(13, OUTPUT);
  Serial.begin(9600);
}

byte gotLowerByte = 0;
byte lowerByte = 0;

void loop() {

  requestSensorData();

  sendSensorData();

  handleSignals();
}

void requestSensorData() {

  // TODO
}

void sendSensorData() {

  // TODO
}

void handleSignals() {

  if (Serial.available() > 0) {

    byte data = Serial.read();

    if (gotLowerByte) {

      gotLowerByte = 0;
      byte higherByte = data;
      unsigned short signal = higherByte << 8 | lowerByte;

      // Handle signal when it is completed received.
      handleSignal(signal);

    } else {

      gotLowerByte = 1;
      lowerByte = data;
    }
  }
}

void handleSignal(unsigned short signal) {
  
  storeSignal(signal);

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
    Wire.endTransmission();
  }
}
