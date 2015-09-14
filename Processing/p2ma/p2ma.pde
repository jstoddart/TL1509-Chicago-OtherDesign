// ///////////////////////////////////////////////
//
// p2ma (Pi To Master Arduino) | The Living | 2015
//
// ///////////////////////////////////////////////

import processing.serial.*;

// //////// Global variables. ////////

Surface surface;
BubbleRenderer br;
Simulator simulator;

// `True` if the simulation is running.
boolean play = true;

// Serial port connecting master Arduino.
Serial masterPort;
// The signal arrays to distribute to slave Arduinos.
short[] signals;
byte[] sensorReadings;

// //////// Global constants. ////////

final int SURFACE_WIDTH = 50;
final int SURFACE_HEIGHT = 50;

final int SIMULATOR_WIDTH = 300;
final int SIMULATOR_HEIGHT = 300;

final int SURFACE_VIEWPORT_WIDTH = 300;
final int SURFACE_VIEWPORT_HEIGHT = 300;

final int RENDERER_VIEWPORT_WIDTH = 300;
final int RENDERER_VIEWPORT_HEIGHT = 300;

final int SIMULATOR_VIEWPORT_WIDTH = 300;
final int SIMULATOR_VIEWPORT_HEIGHT = 300;

final int WINDOW_WIDTH = 900;
final int WINDOW_HEIGHT = 300;

final int CELL_SIZE =
  RENDERER_VIEWPORT_WIDTH /
  (BubbleRenderer.N_NOZZLES_PER_TANK * BubbleRenderer.N_TANK_COLUMNS);
final int ELEM_SIZE = (int)(CELL_SIZE * 0.75);

// The total number of slaves (tanks).
final int N_SLAVES = 22;
// The delay is necessary to avoid losing data at the beginning of transmission.
final int INITIAL_DELAY = 3000;
// Mandatory delay to make communication work, especially for slave Arduinos to
// manipulate digital pins.
final int MANDATORY_DELAY = 0;
// Delay so the LED pattern is visible.
final int LED_DELAY = 10;
// A trigger signal that makes master Arduino to request sensor data from slaves.
final byte TRIGGER_SIGNAL_REQUEST_SENSOR_DATA = 42;

void setup() {

  surface = new Surface(SURFACE_WIDTH, SURFACE_HEIGHT);
  br = new BubbleRenderer(#000001, false);
  simulator = new Simulator(SIMULATOR_WIDTH, SIMULATOR_HEIGHT);

  // //// Controller setup. ////

  // Initialize the signal arrays to distribute to slave Arduinos.
  signals = new short[N_SLAVES];
  sensorReadings = new byte[N_SLAVES];

  // Set up serial port.
  String portName = Serial.list()[0];
  masterPort = new Serial(this, portName, 9600);

  delay(INITIAL_DELAY);
}

void settings() {

  size(WINDOW_WIDTH, WINDOW_HEIGHT);
}

void draw() {

  updateControllers();
  
  // Update the surface and the bubble renderer only when the simulator is
  // not busy.
  if (!simulator.isBusy()) {

    // //// Surface. ////

    PImage imageSurface = surface.render();
    image(imageSurface, 0, 0, 
      SURFACE_VIEWPORT_WIDTH, SURFACE_VIEWPORT_HEIGHT);
    surface.update();

    // //// Bubble renderer. ////

    PImage imageRenderer = br.render(imageSurface, "rect", CELL_SIZE, ELEM_SIZE);
    image(imageRenderer, SURFACE_VIEWPORT_WIDTH, 0, 
      imageRenderer.width, imageRenderer.height);

    // Send signals to simulator only if there is any ripple on
    // the surface.
    if (surface.getRipples().size() > 0) {
      short[][] signals = br.getSignals(imageSurface);
      simulator.send(signals);
    }
  }

  // //// Simulator. ////

  PImage imageSimulator = simulator.render();
  image(imageSimulator, 
    SURFACE_VIEWPORT_WIDTH + RENDERER_VIEWPORT_WIDTH, 0, 
    SIMULATOR_VIEWPORT_WIDTH, SIMULATOR_VIEWPORT_HEIGHT);

  // Update the simulator only if the simulation is playing.
  if (play) simulator.update();
}

void updateControllers() {

  for (int i = 0; i < signals.length; ++i) {

   short signal = signals[i];

   // Write the low and high byte of each short-integer signal
   // to master port.
   masterPort.write((byte)(signal & 0xFF));
   masterPort.write((byte)((signal & 0xFF00) >> 8));
    
   // Increment the signal to make it a counter.
   ++signals[i];
  }

  // Retrieve sensor readings from the master Arduino.
  if (masterPort.available() >= N_SLAVES) {

    for (int tank = 0; tank < N_SLAVES; ++tank) {
      
      int reading = masterPort.read();

      // If the sensor reading is active, generate a ripple at the enter of
      // the tank it is in.
      if (reading != 0) {

        // Center in simulator's coordinate system.
        PVector center = simulator.getTanks().get(tank).getCenter();
        // Scale `center` to the surface's coordinate system.
        center.div(SIMULATOR_WIDTH / SURFACE_WIDTH);

        // Print center coordinates in debugging message.
        println(center.x + ", " + center.y);
        
        // Add a new ripple at the center.
        surface.addRipple(new Ripple(center));
      }
    }
  }

  // Necessary delays.
  delay(MANDATORY_DELAY);
  delay(LED_DELAY);
  
  //// Request sensor data.
  masterPort.write(TRIGGER_SIGNAL_REQUEST_SENSOR_DATA);
}

void mouseClicked() {

  // Click on the surface viewport to generate ripples.
  if ((mouseX >= SURFACE_VIEWPORT_WIDTH) ||
    (mouseY >= SURFACE_VIEWPORT_HEIGHT)) {

    return;
  }

  // Create a ripple at where the mouse clicked.
  if (mouseButton == LEFT) {

    int x = (int) (mouseX * (float) SURFACE_WIDTH / RENDERER_VIEWPORT_WIDTH);
    int y = (int) (mouseY * (float) SURFACE_HEIGHT / RENDERER_VIEWPORT_HEIGHT);

    Ripple ripple = new Ripple(new PVector(x, y));
    surface.addRipple(ripple);
  }
}

void keyPressed() {

  switch (key) {

    // "p" for "pause".
  case 'p':

    // Toggle the `play` flag.
    play = !play;
    break;

    // "s" for "step".
  case 's':

    // We only need to update the simulator, which drives the update
    // of the surface and the bubble renderer.
    simulator.update();
    break;
  }
}