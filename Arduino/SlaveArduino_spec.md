# Slave Arduino

*Specifications for Arduino Uno acting as Slave in i2c communication with a Master Arduino unit*

**INPUTS**

1) Sensor Reading Request

*Request from Master unit, via i2c, for sensor values*

```Arduino
Wire.onRequest( requestHandler );
```

2) Firing Pattern Write

*Data from Master unit, via i2c, to pass to shift out to pumps*

3) IR Sensor Check

*Read left/right pin inputs with boolean OR*

4) Distance Sensor ping

*trigger & listen for echo on ultrasonic sensor, and convert milliseconds to distance (cm)*

**OUTPUTS**

1) Sensor Response

*Data sent over i2c to a Master unit, containing sensor values*

2) Bubble Pattern Fire

*2 Byte firing pattern, passed through shiftOut function, to pumps*

