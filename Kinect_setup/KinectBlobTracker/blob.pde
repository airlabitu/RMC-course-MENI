

class Blob implements Comparable<Blob> {
  float minx;
  float miny;
  float maxx;
  float maxy;
  
  boolean nested = false;

  int id = 0;

  int lifespan;// = maxLife;
  
  int lifetime;

  boolean taken = false;
  
  int maxLife;
  float distThreshold;
  
  ArrayList<DepthPixel> pixelList;
  DepthPixel minDepth;

  Blob(float x, float y, int maxLife_, float distThreshold_) {
    lifetime = 0;
    maxLife = maxLife_;
    distThreshold = distThreshold_;
    
    lifespan = maxLife;
    
    minx = x;
    miny = y;
    maxx = x;
    maxy = y;
    
    pixelList = new ArrayList<DepthPixel>();
    minDepth = new DepthPixel(-1, -1, 999999999);
    
  }
  
  Blob (){ // simple constructor for copying 
  } 

  boolean checkLife() {
    lifespan--; 
    if (lifespan < 0) {
      return true;
    } else {
      return false;
    }
  }


  void show() {
    stroke(255,105,204);
    fill(255, lifespan);
    strokeWeight(2);
    rectMode(CORNERS);
    rect(minx, miny, maxx, maxy);

    textAlign(CENTER);
    textSize(15);
    fill(255,105,204);
    text(id, minx + (maxx-minx)*0.5, maxy - 10);
    textSize(15);
    //text(lifespan, minx + (maxx-minx)*0.5, miny - 10);
    //println("ID", id, "pixelList size", pixelList.size());
    //println("minDepth", minDepth.depth, "X", minDepth.x, "Y", minDepth.y);
    if (minDepth != null){
      fill(255,0,0);
      noStroke();
      ellipse(minDepth.x, minDepth.y, 10, 10);
      //fill(255,105,204);
      //stroke(255,105,204);
    }
  }
  
  void showPixels(){
    //println("PLS:", pixelList.size());
    for (DepthPixel dp : pixelList){
      //println("SH");
      fill(255, 0,0);
      ellipse(dp.x, dp.y, 5, 5);
    }
  }
  
  void add(float x, float y) {
    minx = min(minx, x);
    miny = min(miny, y);
    maxx = max(maxx, x);
    maxy = max(maxy, y);    
  }
  
  void add(float x, float y, int depth) {
    minx = min(minx, x);
    miny = min(miny, y);
    maxx = max(maxx, x);
    maxy = max(maxy, y);
    pixelList.add(new DepthPixel(x, y, depth));
    //minDepth.depth = depth;
    if (depth < minDepth.depth) minDepth = new DepthPixel(x, y, depth);
  }
  
  void become(Blob other) {
    minx = other.minx;
    maxx = other.maxx;
    miny = other.miny;
    maxy = other.maxy;
    lifespan = maxLife;
    pixelList = other.pixelList;
    minDepth = other.minDepth;
    
    // NB: we might need to add the nested attribute here, and maybe other stuff as well
  }

  float size() {
    return (maxx-minx)*(maxy-miny);
  }

  PVector getCenter() {
    float x = (maxx - minx)* 0.5 + minx;
    float y = (maxy - miny)* 0.5 + miny;
    return new PVector(x, y);
  }
  
  float getMinDepth(){
    return minDepth.depth;
  }
  
  int getNrOfPixels(){
    return pixelList.size();
  }

  boolean isNear(float x, float y) {

    float cx = max(min(x, maxx), minx);
    float cy = max(min(y, maxy), miny);
    float d = distSq(cx, cy, x, y);

    if (d < distThreshold*distThreshold) {
      return true;
    } else {
      return false;
    }
  }
  
  // This method is required due to implementing Comparable
  public int compareTo(Blob cb) {
        return floor(cb.size())-floor(size());//(int) Math.signum(size - cb.size);
  }
  
  boolean isInside(float minx_, float miny_, float maxx_, float maxy_){
    if (minx <= minx_ && miny <= miny_ && maxx >= maxx_ && maxy >= maxy_) {
      /*
      println();
      println("stroke(0, 255, 0);");
      println("rect(", minx, ",", miny, ",", maxx, ",", maxy, ");");
      println("stroke(255,0,0);");
      println("rect(",minx_, ",", miny_, ",", maxx_, ",", maxy_, ");");
      println();
      */
      return true;
    }
    return false;
  }
  
  Blob getCopy(){
    Blob b = new Blob();
    
    b.nested = nested;

    b.id = id;
    
    b.lifetime = lifetime;
    b.maxLife = maxLife;
    b.distThreshold = distThreshold;
    
    b.lifespan = lifespan;
    
    b.minx = minx;
    b.miny = miny;
    b.maxx = maxx;
    b.maxy = maxy;
    
    b.pixelList = new ArrayList<DepthPixel>();
    for (DepthPixel dp : pixelList){
      b.pixelList.add(dp.getCopy());
    }
    
    b.minDepth = new DepthPixel(minDepth.x, minDepth.y, minDepth.depth);
    
    return b;
  }
}
