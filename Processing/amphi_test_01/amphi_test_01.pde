//Imports
import java.util.Iterator;

//Object instantiations
ArrayList<Bubble> bubbles;
ArrayList<Tank> tanks;

//global variables
int tanksX = 1;
int tanksY = 1;
int tankDimX = 300;
int tankDimY = 350;
int tankWaterTop = 50;


//Setup
void setup(){
 size(tanksX*tankDimX,tanksY*tankDimY);
 
 bubbles = new ArrayList<Bubble>();
 //bubble = new Bubble(new PVector(width/2, height), 2.0 + random(-0.25,0.25) );
 
 tanks = new ArrayList<Tank>();
 int idx = 0;
 for (int i = 0; i < tanksY; i++){
   for (int j = 0; j < tanksX; j++){
     tanks.add( new Tank( idx, new PVector(j*tankDimX, i*tankDimY), 4));
     idx++;
   }
 }
  
}

//Draw
void draw(){
  background(255);
  
  //iterate through tanks
  Iterator<Tank> it_t = tanks.iterator();
  
  while (it_t.hasNext()){
    Tank t = it_t.next();
    t.run();
  }
  
  //generate new bubbles
  if (frameCount % 5 == 0){
    bubbles.add( new Bubble( new PVector(random(width), height), 10.0+random(-2,2), 100 ) );
  }
  
  //iterate through bubbles
  Iterator<Bubble> it_b = bubbles.iterator();
  
  while (it_b.hasNext()){
    Bubble b = it_b.next();
    b.run();
    if (b.isDead()) {
      it_b.remove();
      println("dead!");
    }
  }
  
  //println(bubbles.size());
  //bubble.run();
  
  
  //println(frameCount);
}
