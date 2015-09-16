// ///////////////////////////////////////////////
//
// p2ma (Pi To Master Arduino) | The Living | 2015
//
// ///////////////////////////////////////////////

import processing.serial.*;

final boolean USE_SENSORS = true;
final boolean USE_SIMULATOR = false;
final boolean SYNC_SIMULATOR_WITH_DEVICE = true;

// //////// Global variables. ////////

Surface surface;
BubbleRenderer br;
Simulator simulator;
PImage imageSurface;
PImage imageRenderer;

// `True` if the simulation is running.
boolean play = true;

// Serial port connecting master Arduino.
Serial masterPort;
// The signal frames to distribute to slave Arduinos over time.
short[][] signalFrames;
int curSignalFrame = -1;
byte[] sensorReadings;

// //////// Global constants. ////////

final int SURFACE_WIDTH = 50;
final int SURFACE_HEIGHT = 50;

final int SIMULATOR_WIDTH = 300;
final int SIMULATOR_HEIGHT = 300;

final int SURFACE_VIEWPORT_WIDTH = 300;
final int SURFACE_VIEWPORT_HEIGHT = 300;

final int RENDERER_VIEWPORT_WIDTH = SURFACE_VIEWPORT_WIDTH;
final int RENDERER_VIEWPORT_HEIGHT = SURFACE_VIEWPORT_HEIGHT;

final int SIMULATOR_VIEWPORT_WIDTH = SURFACE_VIEWPORT_WIDTH;
final int SIMULATOR_VIEWPORT_HEIGHT = SURFACE_VIEWPORT_HEIGHT;

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
// manipulate digital pins and the serial communication between Pi and master
// Arduino.
final int MANDATORY_DELAY = 100;
// A trigger signal that makes master Arduino to request sensor data from slaves.
final byte TRIGGER_SIGNAL_REQUEST_SENSOR_DATA = 42;

// //////// Initialization. ////////

void setup() {

  // Processing 2.x: Set window size here.
  size(WINDOW_WIDTH, WINDOW_HEIGHT);

  surface = new Surface(SURFACE_WIDTH, SURFACE_HEIGHT);
  br = new BubbleRenderer(#000001, false);
  simulator = new Simulator(SIMULATOR_WIDTH, SIMULATOR_HEIGHT);

  // //// Controller setup. ////

  sensorReadings = new byte[N_SLAVES];

  // Set up serial port.
  String portName = Serial.list()[0];
  masterPort = new Serial(this, portName, 9600);

  delay(INITIAL_DELAY);
}

// Processing 3.x: Set window size here.
void settings() {

  size(WINDOW_WIDTH, WINDOW_HEIGHT);
}

// //////// Main loop. ////////

void draw() {

  if (USE_SENSORS) {
    updateFromSensors();
  }

  if (USE_SIMULATOR) {
    updateSimulator();
  } else {
    updateDevice();
  }
}

// //////// Update. ////////

void updateFromSensors() {

  // Retrieve sensor readings from the master Arduino.

  // If sensor readings from all slaves are available.
  if (masterPort.available() >= N_SLAVES) {

    for (int tank = 0; tank < N_SLAVES; ++tank) {

      // If the sensor of Tank <i> reading is active, generate a ripple
      // at the enter of the Tank <i>.

      int reading = masterPort.read();
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
}

void updateSimulator() {

  // Update the surface and the bubble renderer only when the simulator is not busy.
  if (!simulator.isBusy()) {

    updateRender();

    // Send signals to simulator only if there is any ripple on the surface.
    if (surface.getRipples().size() > 0) {
      short[][] signals = br.getSignals(imageSurface);
      simulator.send(signals);
    }
  }

  // Display the simulator render.
  PImage imageSimulator = simulator.render();
  image(imageSimulator, 
    SURFACE_VIEWPORT_WIDTH + RENDERER_VIEWPORT_WIDTH, 0, 
    SIMULATOR_VIEWPORT_WIDTH, SIMULATOR_VIEWPORT_HEIGHT);

  // Update the simulator only if the simulation is playing.
  if (play) simulator.update();
}

void updateDevice() {

  if (!hasSignalFramesToSend()) {    // If there is no more signal frame to send.

    // Nullify `signalFrame` to help with garbage collection.
    signalFrames = null;

    // Update the ripples on the surface and their bubble rendering.
    updateRender();

    // If there are any ripples to render...
    if (surface.getRipples().size() > 0) {

      // Buffer the signal frames and reset the current frame.
      signalFrames = br.getSignals(imageSurface);
      curSignalFrame = 0;

      if (SYNC_SIMULATOR_WITH_DEVICE) {

        // Send the signal frames to simulator as well.
        simulator.send(signalFrames);
      }
    }
  }

  if (hasSignalFramesToSend()) {    // If there are signal frames to send to device.

    // Get the current signal frame.
    short[] signalFrame = signalFrames[curSignalFrame];
    // Send the signal frame to nozzle controllers.
    sendSignalFrame(signalFrame);

    if (SYNC_SIMULATOR_WITH_DEVICE) {
      
      PImage imageSimulator = simulator.render();
      image(imageSimulator,
        SURFACE_VIEWPORT_WIDTH + RENDERER_VIEWPORT_WIDTH, 0,
        SIMULATOR_VIEWPORT_WIDTH, SIMULATOR_VIEWPORT_HEIGHT);
      simulator.update();
    }

    // Move on to the next signal frame.
    ++curSignalFrame;

    // Necessary delay.
    delay(MANDATORY_DELAY);
    
    // Release master to request sensor data.
    masterPort.write(TRIGGER_SIGNAL_REQUEST_SENSOR_DATA);
  }
}

void updateRender() {

  // Update ripples on the surface.
  imageSurface = surface.render();
  image(imageSurface, 0, 0,
    SURFACE_VIEWPORT_WIDTH, SURFACE_VIEWPORT_HEIGHT);
  surface.update();

  // Update the bubble rendering with the updated surface.
  imageRenderer = br.render(imageSurface, "rect", CELL_SIZE, ELEM_SIZE);
  image(imageRenderer, SURFACE_VIEWPORT_WIDTH, 0,
    imageRenderer.width, imageRenderer.height);
}

// //////// Signal frames access. ////////

boolean hasSignalFramesToSend() {

  return (signalFrames != null) && (curSignalFrame < signalFrames.length);
}

void sendSignalFrame(short[] signals) {

  for (int i = 0; i < signals.length; ++i) {

    short signal = signals[i];
    // DEBUG
    // signal = 0x01ff;

    // DEBUG: Even if the entry is set to a constant, slave will occasionally get
    // flipped bytes.
    // signal = 0x01ff;
    if (i == 3) println(binary(signal));

    // Write the low and high byte of each short-integer signal
    // to master port.
    byte loByte = (byte)(signal & 0xFF);
    byte hiByte = (byte)((signal & 0xFF00) >> 8);
 
    // DEBUG
    if (i == 3) println(binary(hiByte) + " - " + binary(loByte));
    
    masterPort.write(loByte);
    masterPort.write(hiByte);
  }
}

// //////// Processing UI event handlers. ////////

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
