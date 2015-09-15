// ///////////////////////////////////////////////
//
// Slave Receiver | The Living | 2015
//
// ///////////////////////////////////////////////

#include <Wire.h>

// //////// Constants. ////////

// I2C address of this slave Arduino.
#define SLAVE_ADDRESS 22

// Number of nozzles.
#define N_NOZZLES 10

// //// Backup pattern. ////

// In case sensor-based patterns do not work, use random patterns
// that are fully contained in this slave Arduino.

// 1 to use random pattern. 0 to not use it.
#define USE_RANDOM_PATTERN 0
// The probability that a single nozzle is turned on.
#define TRIGGER_PROBABILITY 0.8
// The time (in milliseconds) that a random pattern will persist.
#define RANDOM_PATTERN_DELAY 200

// //// Pins. ////

// Latch pin indicates when shift register should start/stop listening.
// The wire is green.
#define LATCH_PIN 6
// Clock pin indicates which output pin to associate data with.
// The wire is blue.
#define CLOCK_PIN 8
// Data pin transfers binary data. The wire is yellow.
#define DATA_PIN 7

// Pins for IR sensor.
#define IR_LEFT_PIN 2
#define IR_RIGHT_PIN 3

// Pins for ultrasonic sensor.
#define ULTRASONIC_TRIGGER_PIN 4
#define ULTRASONIC_ECHO_PIN 5

// Pin for built-in LED.
#define LED_PIN 13

// //// Ultrasonic sensor constants. ////

#define ULTRASONIC_MIN_DIST 10
#define ULTRASONIC_MAX_DIST 150
#define ULTRASONIC_DELAY 60

// //////// Global variables. ////////

// IR sensor reading.
byte irSensorReading = 0;
// Ultrasonic sensor reading.
byte usSensorReading = 0;
// Shadow pattern to render when ultrasonic sensor has a valid reading.
unsigned short shadowSignal = 0b0101010101010101;
// Frames remaining before the next random pattern update.
int randomPatternUpdateCountdown = 0;

// //////// Initialization. ////////

void setup() {

  // Join I2C bus.
  Wire.begin(SLAVE_ADDRESS);

#if not USE_RANDOM_PATTERN

  // Register event handlers for I2C communications.
  Wire.onReceive(receiveEvent);
  Wire.onRequest(requestEvent);

#endif

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

  pinMode(ULTRASONIC_TRIGGER_PIN, OUTPUT);
  pinMode(ULTRASONIC_ECHO_PIN, INPUT);
}

// //////// Main loop. ////////

void loop() {

#if USE_RANDOM_PATTERN

  short signal = 0;
  for (int i = 0; i < N_NOZZLES; ++i) {
    // Turn on the nozzle at a probability of
    // `TRIGGER_PROBABILITY`.
    float r = rand() / (float) RAND_MAX;
    if (r < TRIGGER_PROBABILITY) signal |= 1;
    signal <<= 1;
  }

  signal >>= 1;
  fireNozzles(signal);
  delay(RANDOM_PATTERN_DELAY);

#else

  // Update sensor readings.
  readIrSensor();
  readUsSensor();

  if (usSensorReading) {

    // Create a vibrating shadow pattern if the ultrasonic sensor
    // reading is within range.
    fireNozzles(shadowSignal);
    // Shake the shadow!
    shadowSignal = (shadowSignal << 1) | (shadowSignal >> 15 && 1);

  } else {

    // If there is no valid ultrasonic reading, remove the shadow.
    fireNozzles(0);
  }
  // Delay so that this slave is able to pick up events.
  delay(ULTRASONIC_DELAY);

#endif
}

// //////// Event handlers. ////////

void receiveEvent(int bytes) {

  // If a complete signal is received.
  if (Wire.available() >= 2) {

    // Assemble the signal.
    byte loByte = Wire.read();
    byte hiByte = Wire.read();
    // A temporary fix of flipping bytes:
    // The high byte should never exceed 11b. So we switch the bytes
    // in case this happens. Since it is just two bits, error should be
    // tolerable.
    unsigned short signal =
      (hiByte > 0b11) ? ((loByte << 8) | hiByte): ((hiByte << 8) | loByte);

    // //// DEBUG ////
    Serial.print("[SIGNAL FROM MASTER] hi=");
    Serial.print(hiByte, BIN);
    Serial.print(" lo=");
    Serial.print(loByte, BIN);
    Serial.print(" word=");
    Serial.println(signal, BIN);

    // If the ultrasonic sensor reading is within range,
    // overlap the shadow signal with the signal from master.
    if (usSensorReading) {
      signal |= shadowSignal;
    }

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

  // //// IR sensor. ////

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

int readUsSensor() {

  // //// Ultrasonic sensor. ////

  long duration, distanceInCm;

  // Pulse the trigger pin and measure the response time on the echo pin.
  // Pulse `LOW` first to ensure clean signal.
  digitalWrite(ULTRASONIC_TRIGGER_PIN, LOW);
  delayMicroseconds(1);

  digitalWrite(ULTRASONIC_TRIGGER_PIN, HIGH);
  delayMicroseconds(5);
  digitalWrite(ULTRASONIC_ECHO_PIN, LOW);

  // Measure echo time.
  duration = pulseIn(ULTRASONIC_ECHO_PIN, HIGH);

  // Convert echo time to distance.
  distanceInCm = msToCm(duration);

  // Debugging messages.
//  Serial.print("[ULTRASONIC] ");
//  Serial.println(distanceInCm);

  // Mark the ultrasensor reading if the distance is
  // within specified range.
  if (distanceInCm >= ULTRASONIC_MIN_DIST &&
      distanceInCm <= ULTRASONIC_MAX_DIST) {

    usSensorReading = 1;

  } else {

    usSensorReading = 0;
  }
}

// //////// Utilities. ////////

long msToCm(long microseconds) {

  // Speed of sound
  // = 340.29 m/s = 3.4029e-4 m/us
  // = 3.4029e-2 m/us

  // Time includes round trip travel.
  return microseconds * 0.5 * 3.4029e-2;
}

