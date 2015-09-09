#Processing Sketch Spec

*Specifications for Processing sketch controlling tank behavior via serial communication to a Master Arduino unit*

**INPUTS**
1) Recieve updated sensor data

* Recieves sensor data in byte format from Master Arduino via Serial, parses data, and updates tank object values.*

2) Recieves ready signal from Master

* Recieves ready signal (">") from Master Arduino via Serial, indicating it is ready for next command

**OUTPUTS**
1) Request Sensor Value Update

* Sends formatted request for a specified Slave Arduino's sensor data to the Master Arduino via Serial.*

2) Sends Firing Pattern

* Sends formatted firing data to Master Arduino over Serial for distribution to specified slave unit.*

