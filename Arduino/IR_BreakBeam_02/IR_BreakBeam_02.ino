const int IR_left = 3;
const int IR_right = 4;

//timer
unsigned long previousMillis;
int interval = 2000;
boolean trigger;

void setup() {
  Serial.begin(9600);
  pinMode(IR_left, INPUT);
  pinMode(IR_right, INPUT);
  
  trigger = false;
}

void loop() {
  unsigned long currentMillis = millis();
  
  int val = digitalRead(IR_left) | digitalRead(IR_right);
  Serial.print(val);
  
  //check if the trigger has already been fired
  if( trigger == false ){
    //if sensors detect frogs
    if( val ){
      //trigger "fired" signal
      trigger = true;
    }
  }
  
  //some function to release trigger if data has been sent
  //after sending data, trigger is returned to false
  //void requestEvent()
  
}
