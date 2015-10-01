## Deployment Notes

### 1. Files

#### 1.1 `Processing/p2ma`

This directory contains the program to be deployed on Raspberry Pi, which is
responsible for communication between Pi and master Arduino and provides a
simulator for visualization and debugging.

#### 1.2 `Arduino/master_writer2/master_writer2.ino`

The code to upload to Master Arduino, responsible for collecting sensor
readings from slave Arduinos and sending them to Pi, and collecting bubble
pattern signals from Pi and distributing them to corresponding slave Arduinos.

#### 1.3 `Arduino/slave_receiver2/slave_receiver2.ino`

The code to upload to every slave Arduino, responding to requests for sensor
readings and issue commands received from master Arduino to nozzle controllers.
Remember to change the I2C addresses before uploading it to the next Arduino.

### 2. Pin Numbers

The pin settings below can also be found in `slave_receiver2.ino`. If you
change the wiring, make sure to update these constants consistently.

#### 2.1 LED/Nozzle Controller
```c
// Latch pin indicates when shift register should start/stop listening.
// The wire is green.
#define LATCH_PIN 6
// Clock pin indicates which output pin to associate data with.
// The wire is blue.
#define CLOCK_PIN 8
// Data pin transfers binary data. The wire is yellow.
#define DATA_PIN 7
```

#### 2.2 IR Sensor
```c
#define IR_LEFT_PIN 2
#define IR_RIGHT_PIN 3
```

#### 2.3 Ultrasonic Sensor
```c
#define ULTRASONIC_TRIGGER_PIN 4
#define ULTRASONIC_ECHO_PIN 5
```

### 3. I2C Addresses

By default, the I2C addresses for the slave Arduinos start from 19
consecutively, as indicated by `SLAVE_ADDRESS_START` on `Line 15` of
`master_writer2.ino` . The address for a specific slave Arduino can be found
on `Line 12` in `slave_receiver2.ino`, i.e. `SLAVE_ADDRESS`. If you want to
change this start address, please make sure to change `SLAVE_ADDRESS_START`
and update each `SLAVE_ADDRESS` and upload the program to slave Arduinos again.

### 5. Delays

Proper delays are crucial (but fragile) to make all these pieces talk. If
the communication behaves weirdly, one place to look at is these delays.

#### 5.1 `p2ma.pde`

```java
// The delay is necessary to avoid losing data at the beginning of
// transmission.
final int INITIAL_DELAY = 3000;
...
// Mandatory delay to make communication work, especially for slave Arduinos to
// manipulate digital pins and the serial communication between Pi and master
// Arduino.
final int MANDATORY_DELAY = 100;
```

#### 5.2 `master_writer2.ino`

```c
// Time to keep nozzles on (in milliseconds).
#define NOZZLE_DELAY 200
```

### 5. Backup Plan

In case bubble pattern generation based on sensor readings does not work
relieably, we have a backup plan of randomly emitting bubbles. To enable
random mode (and disable default mode), set `USE_RANDOM_PATTERN` on `Line 23`
in `slave_receiver2.ino` to `1`. The two constants below controls the random
behavior, i.e. overall bubble density (`TRIGGER_PROBABILITY`) and random
pattern changing frequency (`RANDOM_PATTERN_DELAY`).

### 6. Debugging

To generate test signals from Processing, left click on the first part of the
program window. These signals will be dependent on the sensor readings and be
sent to the simulator and the physical devices depending on the settings
below.

To simulate the bubble generation in the UI only:
- Set `USE_SIMULATOR` to `true`.

To issue signals to Arduinos and visualize the bubbles in simulator in sync
(ideal for testing):
- Set `USE_SIMULATOR` to `false`.
- Set `SYNC_SIMULATOR_WITH_DEVICE` to `true`.

To issue signals to Arduinos only (**ideal for deploying since there is no
overhead for simulation**):
- Set `USE_SIMULATOR` to `false`.
- Set `SYNC_SIMULATOR_WITH_DEVICE` to `false`.

Orthogonally, to enable/disable sensor readings in both cases:
- Set `USE_SENSORS` to `true`/`false`.

Finally, please let me know if you encounter any problems when deploying and
running the program.

### 7. Auto-Start

To automatically start the program once Raspberry Pi is turned on:

1. Start `raspi-config` in terminal mode or in terminal application:

        sudo raspi-config

2. Go to `Enable Boot to Desktop/Scratch` and choose to boot to desktop on startup.

3. Once in desktop environment, open a terminal and launch `nano`:

        sudo nano /etc/xdg/lxsession/LXDE-pi/autostart

The last line involving `processing-java` is responsible for auto-starting the program. It should be something like this:

        /home/pi/processing-2.2.1/processing-java --run --force --sketch=/home/pi/TL1509-Chicago-OtherDesign/Processing/p2ma --output=/home/pi/TL1509-Chicago-OtherDesign/Processing/p2ma/out

- Reference: [How To Autostart Apps In Rasbian LXDE Desktop](http://www.raspberrypi-spy.co.uk/2014/05/how-to-autostart-apps-in-rasbian-lxde-desktop/)
