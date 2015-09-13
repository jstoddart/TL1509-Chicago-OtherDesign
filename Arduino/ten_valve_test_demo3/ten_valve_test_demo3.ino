//
//
//   TEN VALVE TANK SCRIPT
//
//   Code for a single Arduino-compatible board to run a tank featuring ten solenoid
//   valves controlled via two 8-bit shift registers. Solenoid firing is controlled
//   via binary with a 16-bit signal. Bits 0-9 control solenoids, bits 13-15 control
//   signaling to an adjacent arduino, and bits 10-12 are unused
//   Ultrasonic Rangefinder sensor replace button
//
//   Version: 3.0
//   Date: 10 August, 2015
//   Author: Jim Stoddart, The Living / An Autodesk Studio
//
//

/* **** PIN RESERVATIONS **** */

//Pin connections to 8-bit Shift Register (74HC595)
//Latch pin indicates when shift register should start/stop listening
const int latchPin = 8;
//Clock pin indicates which output pin to associate data with
const int clockPin = 12;
//Data pin transfers binary data t
const int dataPin = 11;

//LED pin for debugging
const int LEDpin = 13;

//Signalling pin
const int signalPin = 6;

/* **** GLOBAL VARIABLES **** */

//Signals to solenoids are encoded as 16-bit Binary Values
//Bits 0-9 control solenoids
//Bits 10-12 are unused
//Buts 13-15 control Arduino-to-Arduino output signals
//Shift registers accept 8-bit Binary Values so encoded signal
//is split into two 8-bit (1 byte) signals

//High byte (Right-most bits) - Pins 0-7
byte dataHi;
//Low byte (Left-most bits) - Pins 8-15
byte dataLo;

//Arrays for holding 16-bit firing patterns
//Sequence firing up
int dataU[10];
//sequence firing to right
int dataR[10];
//Sequence firing to left
int dataL[10];
//test 1,2 sequence
int dataT[10];
//Sequence for all off
int dataOff;
int dataOn[2];


//Timing Variables
int fireTime = 100;
int interTime = 200;
int waitTime = 100;
int countDown;

//MASTER SLAVE Variables
boolean master = true;

//COUNTER
int counter;
int* prevArray;


/* **** SETUP **** */

void setup() {
  //Setup latch pin for Shift-Register
  pinMode(latchPin, OUTPUT);

  Serial.begin(9600);

  //LED Pin (for debugging)
  pinMode(LEDpin, OUTPUT);

  //Seed patterns for generating Left and Right
  //signal patterns
  int startL = 0b0000000000000001;
  int startR = 0b0000001000000000;

  //Generate left and right signal patterns through bitshifts
  for (int i = 0; i < 10; i++) {
    dataL[i] = startL << i;
    dataR[i] = startR >> i;
    dataT[i] = dataL[i] | dataR[i];
  }

  //Generate Up pattern (Chevron)
  dataU[0] = 0b0000000000110000;
  dataU[1] = 0b0000000001001000;
  dataU[2] = 0b0000000010000100;
  dataU[3] = 0b0000000100000010;
  dataU[4] = 0b0000001000000001;
  dataU[5] = 0b0000000000110000;
  dataU[6] = 0b0000000001001000;
  dataU[7] = 0b0000000010000100;
  dataU[8] = 0b0000000100000010;
  dataU[9] = 0b0000001000000001;
  
  /*
  dataT[0] = 0b0000000000000001;
  dataT[1] = 0b0000000000000010;
  dataT[2] = 0b0000000000000100;
  dataT[3] = 0b0000000000001000;
  dataT[4] = 0b0000000000010000;
  dataT[5] = 0b0000000000100000;
  dataT[6] = 0b0000000001000000;
  dataT[7] = 0b0000000000000000;
  dataT[8] = 0b0000000000000100;
  dataT[9] = 0b0000000000001000;
  */

  //Off pattern
  dataOff = 0b0000000000000000;

  //On Pattern
  dataOn[0] = 0b0000000101010101;
  dataOn[0] = 0b0000001010101010;

  counter = 0;

  countDown = 0;

  allOff( 25 );
  allOn( 100 );
  allOff( 25 );

  Serial.println();
  Serial.println("Ready!");
}

void loop() {
  //ensure internal LED is off
  digitalWrite(LEDpin, LOW);

  //firing boolean
  boolean fire = false;

  //check trigger


  //Pointer for pattern array to fire
  int* arrayPt;


  if (counter % 3 == 0 ){
    arrayPt = dataL;
    fire = true;
  } else if( counter % 2 == 0 ) {
    arrayPt = dataL;
    fire = true;
  } else {
    arrayPt = dataL;
    fire = true;
  }

  prevArray = arrayPt;
  counter++;
  Serial.println( counter );


  if (fire) {
    //turn on internal LED
    digitalWrite(LEDpin, HIGH);

    //loop through array and send out data
    for (int j = 0; j < 10; j++) {
      dataLo = lowByte( arrayPt[j]);
      dataHi = highByte( arrayPt[j]);
      //ground Latch pin during transmission
      digitalWrite(latchPin, 0);
      //send byte data
      shiftOut(dataPin, clockPin, dataHi);
      shiftOut(dataPin, clockPin, dataLo);
      //set Latch pin to High to terminate message
      digitalWrite(latchPin, 1);
      delay(fireTime);
      allOff(interTime);

    }
    if (master) {
      allOff(waitTime);
    }
  }

  //turn off internal LED
  digitalWrite(LEDpin, LOW);
  Serial.println("Fired");

}

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

void allOff(int delayTime) {
  //turn off
  digitalWrite(latchPin, 0);

  dataLo = lowByte( dataOff );
  dataHi = highByte( dataOff );

  shiftOut(dataPin, clockPin, dataLo);
  shiftOut(dataPin, clockPin, dataHi);

  digitalWrite(latchPin, 1);
  delay(delayTime);
}

void allOn( int delayTime ) {
  for (int i = 0; i < 2; i++) {
    digitalWrite(latchPin, 0);

    dataLo = lowByte( dataOn[i] );
    dataHi = highByte( dataOn[i] );

    shiftOut( dataPin, clockPin, dataLo);
    shiftOut( dataPin, clockPin, dataHi);

    digitalWrite(latchPin, 1);
    delay(delayTime);
    allOff(interTime);
  }
}

float msToMM(long microseconds) {
  //speed of sound 340.29 m/s
  //or .34029 mm/microseconds
  //or inverted 2.9387 microseconds / mm
  //time include round trip travel so divide by half
  return (microseconds * 0.5 / 2.9387);
}

long ping(int trigger, int echo) {
  //PING - pulse of HIGH for 2+ microseconds
  //with a short LOW pulse beforehand for clarity
  digitalWrite(trigger, LOW);
  delayMicroseconds(5);
  digitalWrite(trigger, HIGH);
  delayMicroseconds(5);
  digitalWrite(trigger, LOW);

  //read the ECHO pin - HIGH pulse duration
  //converted to distances using the speed
  //of sound - 1130 ft/sec
  return pulseIn(echo, HIGH);
}

