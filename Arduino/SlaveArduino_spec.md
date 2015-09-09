# Slave Arduino

*Specifications for Arduino Uno acting as Slave in i2c communication with a Master Arduino unit*

**INPUTS**

1) Sensor Reading Request

*Request from Master unit, via i2c, for sensor values*

Initiated by:
`Wire.onRequest( eventHandler );`
Response:
```Arduino
void eventHandler(){
	byte data = checkSensors();
	Wire.write(data);
	}
```


2) Firing Pattern Write

*Data from Master unit, via i2c, to pass to shift out to pumps*

Initiated by: `Wire.onRecieve( eventHandler )`

Data format: int (2 bytes) `0b0000000000000001`

Response:
```Arduino
void eventHandler(){
	fireNozzles( data );
}
```

3) IR Sensor Check

*Read left/right pin inputs with boolean OR*

4) Distance Sensor ping

*trigger & listen for echo on ultrasonic sensor, and convert milliseconds to distance (cm)*

**OUTPUTS**

1) Sensor Response

*Data sent over i2c to a Master unit, containing sensor values*

2) Bubble Pattern Fire

*2 Byte firing pattern, passed through shiftOut function, to pumps*

**GLOBAL VARIABLES**
```Arduino
#include <Wire.h>

//Verbose Mode
#define VERBOSE (0)

//i2c bus slave address
#define ADDRESS (8)

//i2c pin reservations
#define I2C_DATA (4)
#define I2C_CLOCK (5)

//shift register functionality
#define SHIFT_LATCH (8)
#define SHIFT_CLOCK (12)
#define SHIFT_DATA (11)
//byte data per shift register
byte dataHi, dataLo;

//ultrasonic sensor
#define SONIC_TRIG (6)
#define SONIC_ECHO (7)
//distance reading minimum & maximum
#define SONIC_MIN (10)
#define SONIC_MAX (150)

//IR sensor
#define IR_LEFT (10)
#define IR_RIGHT (9)

#define FIRE_TIME (100)
int dataOff = 0b0000000000000000;
```

**FUNCTIONS**

*Setup*
```Arduino
void setup(){
	Wire.begin(ADDRESS);

	//setup Shift Register pins
	pinMode(SHIFT_LATCH, OUTPUT);
	pinMode(SHIFT_CLOCK, OUTPUT);
	pinMode(SHIFT_DATA, OUTPUT);

	//setup Ultrasonic Rangefinder pins
	pinMode(SONIC_TRIG, OUTPUT);
	pinMode(SONIC_ECHO, INPUT);

	//setup IR Breakbeam sensor pins
	pinMode(IR_LEFT, INPUT);
	pinMode(IR_RIGHT, INPUT);

	//slave specific i2c commands
	Wire.onRequest( checkSensors );
	Wire.onRecieve( fireBubbles );
}
```

*Check Sensors*
```Arduino
void checkSensors(){
	//check values from sensors
	int IRstatus = checkIRstatus();
	int distance = ping();
	
	//format data for transmission
	byte data = formatData(IRstatus, distance);

	//send data over i2c to master
	Wire.write( data );
}

unsigned int checkIRstatus(){
	return (digitalRead(IR_LEFT) | digitalRead(IR_RIGHT));
}

int ping(){
	long duration, cm;

	//pulse the trigger pin and measure the response time on the echo pin
	//Pulse LOW first to ensure clean signal
	digitalWrite(SONIC_TRIG, LOW);
	delayMicroseconds(1);
	
	digitalWrite(SONIC_TRIG, HIGH);
	delayMicroseconds(5);
	digitalWrite(SONIC_TRIG, LOW);

	//measure echo time
	duration = pulseIn(SONIC_ECHO, HIGH);

	//convert echo time to distance
	cm = msToCM(duration);

	//clamp distance values to min and max
	cm = max( SONIC_MIN, cm);
	cm = min( SONIC_MAX, cm);

	return int(cm);
}

long msToCM( long microseconds ){
	//speed of sound - 340.29 m/s
	//or 29.3867 cm/ms
	//time includes round trip travel so half
	return (microseconds * 0.5 / 29.3867);
}

byte formatData( int IR_val, int dist ){
	//distance data occupies the lowest 7 bits
	//IR sensor data is shifted to occupy the highest bit
	return dist | (IR_val << 7);
}
```

*Fire Bubbles*
```Arduino
//
void fireBubbles(int numBytes){
	while( 1 < Wire.available() ){
		dataLo = Wire.read();

	}
	dataHi = Wire.read();

	//ground latch pin to begin transmission
	digitalWrite(SHIFT_LATCH, 0);
	//send byte data
	shiftOut( SHIFT_DATA, SHIFT_CLOCK, dataHi);
	shiftOut( SHIFT_DATA, SHIFT_CLOCK, dataLo);
	//set latch pin to HIGH to end transmission
	digitalWrite(SHIFT_LATCH, 1);

	delay(FIRE_TIME);

	allOff();

}

void shiftOut( int dataPin, int clockPin, byte dataOut ){
	int i = 0;
	int pinState;
	pinMode(clockPin, OUTPUT);
	pinMode(dataPin, OUTPUT);

	//clear pins
	digitalWrite(dataPin, 0);
	digitalWrite(clockPin, 0);
	
	for (i = 7; i >= 0; i--) {
    	digitalWrite(clockPin, 0);

    	if ( dataOut & (1 << i) ) {
      		pinState = 1;
    	} else {
      		pinState = 0;
    	}

    	//set pin to pinState
    	digitalWrite(dataPin, pinState);
    	//register shift to clock
    	digitalWrite(clockPin, 1);
    	//clear data pin
    	digitalWrite(dataPin, 0);
  	}

  	//stop shifting
  	digitalWrite(clockPin, 0);
}

void allOff() {
  digitalWrite(SHIFT_LATCH, 0); //ground latch pin to begin transmission

  dataLo = lowByte( dataOff );
  dataHi = highByte( dataOff );

  shiftOut(SHIFT_DATA, SHIFT_CLOCK, dataLo);
  shiftOut(SHIFT_DATA, SHIFT_CLOCK, dataHi);

  digitalWrite(SHIFT_LATCH, 1); //set latch pin to HIGH to end transmission
}
```
