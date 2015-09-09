class Tank {
  //index of tank
  int id;
  //number of emitters
  int emit_ct;
  //tank location (top-right)
  PVector location;

  //emitter dims
  int emit_dim = 6;

  Tank(int idx, PVector loc, int emit) {
    id = idx;
    location = loc;
    emit_ct = emit;
  }

  void run() {
    display();
  }

  void display() {
    //draw water
    noStroke();
    fill(150);
    rect(location.x, location.y+tankWaterTop, tankDimX, tankDimY - tankWaterTop);

    float div = tankDimX / ((2 * emit_ct));
    for (int i = 0; i < emit_ct; i++) {
      float offset = div + (div*2)*i;
      noStroke();
      fill(255, 0, 0);
      rect(offset, height-emit_dim, emit_dim, emit_dim);
    }
  }
}

