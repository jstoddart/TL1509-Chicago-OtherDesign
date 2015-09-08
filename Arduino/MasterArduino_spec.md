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


