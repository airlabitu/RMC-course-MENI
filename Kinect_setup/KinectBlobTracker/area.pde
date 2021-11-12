class Area{
  int x, y, radius;
  
  Area(int x_, int y_, int radius_){
    x = x_;
    y = y_;
    radius = radius_;
  }
  
  void show(){
    noFill();
    stroke(255, 0, 0);
    circle(x, y, radius*2);
  }
  
  boolean isInside(int x2, int y2){
    if (dist(x, y, x2, y2) < radius) return true;
    return false;
  }
}
