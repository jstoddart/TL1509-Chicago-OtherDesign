# Master Arduino

*Specifications for Arduino Uno acting as Master in i2c communication between Processing sketch and Slave Arduino units*

**INPUTS**

1) Processing Sensor Reading Request

*Command from Processing, via Serial, to request sensor values from a given Slave unit*

2) Processing Firing Pattern Delivery

*Command from Processing, via Serial, to send a given firing pattern to a given Slave*

3) Slave Sensor Data Read

*Sensor values from Slave, via i2c and in response to a request, to be passed to Processing*

**OUTPUTS**

1) Slave Sensor Request

*Request Signal over i2c to a given Slave unit, requesting a given number of bytes of data*

2) Slave Pattern Delivery

*Write Signal, over i2c to a given Slave unit, of firing pattern*

3) Processing Sensor Data Send

*Write signal, over serial to Processing, of given Slave unit's sensor data*



**GLOBAL VARIABLES**
```Arduino
#include <Wire.h>

//Verbose mode
#define VERBOSE (0);

//Serial communications
//constants
#define BAUD (9600) //serial communication bitrate
#define MAX_BUF (64) //max serial buffer size
#define TIMEOUT_OK (100) //timeout length

//variables
char buffer[MAX_BUF]; //serial buffer
int sofar; //serial buffer progress
static long last_cmd_time; //prevent timeouts

//i2c pin reservations
const int i2cData = 4;
const int i2cClock = 5;
```

**FUNCTIONS**

*Setup*
```Arduino
void setup(){
	sofar = 0; //initialize serial read buffer

	Serial.begin(BAUD); //initialize serial port
	
	Wire.begin(); //join i2c bus

	ready();
}
```

*Loop*
```Arduino
void loop(){
	SerialListen(); //listen for communication on serial port

	//check for timeout. if true, send a new ready signal
	if( (millis() - last_cmd_time) > TIMEOUT_OK ){
		ready();
	}
}
```

*Signal Ready*
```Arduino

void ready(){
	//clear serial input buffer
	sofar = 0;
	//send ready signal to Serial
	Serial.print(F("\n> "));
	last_cmd_time = millis();
}
```

*Read from Serial*
```Arduino

void SerialListen(){
	//listen for serial commands
	while(Serial.available() > 0){
		char c = Serial.read();
		if ( sofar < MAX_BUF ) buffer[ sofar++ ] = c;
		if ( c == '\n' || c == '\r') {
			buffer[ sofar ] = 0;

			//echo confirmation in Verbose Mode
			if( VERBOSE > 0 ){
			Serial.println( buffer );
			}

			processCommand();
			ready();
			break;
		}
	}
}
	
```

*Process Command*
```Arduino

//Search through serial input for coded value
void parseNumber(char code, float val){
	char *ptr = buffer;
	while ( ptr && *ptr && ptr < buffer + sofar ){
		if( *ptr == code ){
			return atof(ptr + 1);
		}
	ptr = strchr(ptr, ' ') + 1;
	}
return val;
}

void processCommand(){
	//check for blank lines
	if ( buffer[0] = ';' ) return;

	long cmd;

	//Sensor requests will be prepended with the character "A"
	cmd = parseNumber( 'A', -1);
	if (cmd > 0){
		sensorRequest(cmd);
	}

	//Firing commands will be prepended with the character "B"
	cmd = parseNumber( 'B', -1);
	if (cmd > 0){

		int pattern = parseNumber('P', -1);

		if (pattern > 0){
			fireCommand(cmd, pattern);
		}
	}



}

```
	
