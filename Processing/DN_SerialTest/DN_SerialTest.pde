/**
 * Simple Write. 
 * 
 * Check if the mouse is over a rectangle and writes the status to the serial port. 
 * This example works with the Wiring / Arduino program that follows below.
 */


import processing.serial.*;

Serial myPort;  // Create object from Serial class
int val;        // Data received from the serial port

void setup() 
{
  size(200, 200);
  // I know that the first port in the serial list on my mac
  // is always my  FTDI adaptor, so I open Serial.list()[0].
  // On Windows machines, this generally opens COM1.
  // Open whatever port is the one you're using.
  String portName = Serial.list()[0];
  myPort = new Serial(this, portName, 9600);
}

void draw() {
//  background(255);
//  if (mouseOverRect() == true) {  // If mouse is over square,
//    fill(204);                    // change color and
//    myPort.write("0");              // send an H to indicate mouse is over square
//    println("0");
//  } 
//  else {                        // If mouse is not over square,
//    fill(0);                      // change color and
//    myPort.write("1");              // send an L otherwise
//    println("1");
//  }
//  rect(50, 50, 100, 100);         // Draw a square

  while (myPort.available() > 0) {
    println(myPort.read());
  }

  short[] signals = new short[2];
  signals[0] = 123;
  signals[1] = 456;

  for (int i = 0; i < signals.length; ++i) {
      short signal = signals[i];
      myPort.write(signal & 0xFF);
      myPort.write((signal & 0xFF00) >> 8); 
//      delay(1000);
//      myPort.write(1); 
      delay(100);
  }
  delay(1000);
}
