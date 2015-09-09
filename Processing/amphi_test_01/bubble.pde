class Bubble {
  PVector location;
  PVector velocity;
  PVector acceleration;
  float size;
  float top;
  
  //terminal velocity
  float term_vel;
  
  //material constants
  float air_dens = 1.204;
  float h20_dens = 1000;
  float h20_visc = 0.14;
  float g = 980;
  float dyn = 0.0001;
  
  Bubble(PVector loc, float sz, float tp){
    
    location = loc;
    size = sz;
    top = tp;
    
    //bubbles start stationary
    velocity = new PVector(0,0);
    acceleration = new PVector(0, -(h20_dens - air_dens)*dyn);
    //terminal velocity via: http://isites.harvard.edu/fs/docs/icb.topic1032465.files/Final%20Projects/Fluids%20Drag/Terminal%20Velocity.pdf
    term_vel = (1.0/9.0) * pow(size/20.0,2) * (g) * (h20_visc);
    //term_vel = (2 * h20_dens * g)/(9 * h20_visc) * pow(size/20.0,2)*dyn;
    
    
    println(term_vel);
  }
  
  void run(){
    update();
    display();
  }
  
  void display(){
    stroke(255);
    strokeWeight(2);
    if (velocity.mag() == term_vel){
      fill(255);
    } else {
      fill(255,50);
    }
    
    //textSize(10);
    //fill(0);
    //text(velocity.mag(), location.x+10, location.y);
    //text(term_vel, location.x+10, location.y+10);

    ellipse(location.x, location.y, size, size);
  }
  
  void update(){
    float f = (0.5)*(h20_dens)*pow(velocity.mag()/100.0,2)*(0.50)*(PI * pow(size/20.0,2));
    //println(f);
    PVector friction = new PVector(0, f);
    PVector force = new PVector(0,0);
    force.add(friction);
    force.add(acceleration);
    velocity.add(force);
    velocity.limit(term_vel);
    
    location.add(velocity);
  }
  
  boolean isDead() {
    if (location.y < top){
      return true;
    } else {
      return false;
    }
  }
      
    
    
  }
    
