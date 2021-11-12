class Tracker{
  
  //Kinect kinect;
  
  // Depth image
  PImage trackerDataMap;
  int [] rawDepthData;
  private int minDepth =  60; // 60
  int maxDepth = 1000; //1000;
  //float angle;
  
  int blobCounter = 0;
  
  int maxLife = 0; // original value 50
  int minBlobSize = 500; // area : h*w of blob
  
  color trackColor; 
  float threshold = 40;
  float distThreshold = 50;
  
  ArrayList<Area> ignoreAreas = new ArrayList<Area>();
  
  ArrayList<Blob> blobs = new ArrayList<Blob>();
  ArrayList<Blob> blobsFiltered = new ArrayList<Blob>();
  boolean nestedBlobsFilter = true;
  
  //Tracker(PApplet this_){
  Tracker(){
    trackColor = color(255);
    //kinect = new Kinect(this_);
    //kinect.initDepth();
    //angle = kinect.getTilt();
    //trackerDataMap = new PImage(kinect.width, kinect.height);
    trackerDataMap = new PImage(640,480);
  }
  
  void detectBlobs(int [] rawDepthData_){
    //if (debug) println("rawDepth:", rawDepthData_, rawDepthData_[0]);
    rawDepthData = rawDepthData_;    
    if (loading) return;
    // alter input image based on threshold, needed for altering the Shiffmann code to work with Kinect images instead
    // Threshold the depth image
    //int[] rawDepth = kinect.getRawDepth();
    for (int i=0; i < rawDepthData.length; i++) {
      if (rawDepthData[i] >= minDepth && rawDepthData[i] <= maxDepth) {
        trackerDataMap.pixels[i] = color(255);
      } 
      else {
        trackerDataMap.pixels[i] = color(0);
      }
    }
    findBlobs(); // run blob finder
    blobsFiltered = copyBlobsList();
    //println("blobs size", blobs.size(), "blobsFiltered size", blobsFiltered.size());
    //removeNestedBlobs();
    if (nestedBlobsFilter) removeNestedBlobs();
    
  }
  
  /*
  void detectBlobs(){
    
    // alter input image based on threshold, needed for altering the Shiffmann code to work with Kinect images instead
    // Threshold the depth image
    int[] rawDepth = kinect.getRawDepth();
    for (int i=0; i < rawDepth.length; i++) {
      if (rawDepth[i] >= minDepth && rawDepth[i] <= maxDepth) {
        //depthImg.pixels[i] = color(255);
        trackerDataMap.pixels[i] = color(255);
      } 
      else {
        //depthImg.pixels[i] = color(0);
        trackerDataMap.pixels[i] = color(0);
      }
    }
    findBlobs(); // run blob finder
  }
  */
  
  
  // overloaded function for simulation purpose
  void detectBlobs(PImage videoFrame){
    if (loading) return;
    trackerDataMap = videoFrame;
    findBlobs(); // run blob finder
    blobsFiltered = copyBlobsList(); // overwrite with original blob list
    if (nestedBlobsFilter) removeNestedBlobs();
  }
  
  
  void findBlobs(){
    
    ArrayList<Blob> currentBlobs = new ArrayList<Blob>();
  
    // Begin loop to walk through every pixel
    for (int x = 0; x < trackerDataMap.width; x++ ) {
      for (int y = 0; y < trackerDataMap.height; y++ ) {
        
        if (isIgnored(x, y)) continue; // procees to next pixel if this one is in a ignored area
        
        int loc = x + y * trackerDataMap.width;
        // What is current color
        color currentColor = trackerDataMap.pixels[loc];
        float r1 = red(currentColor);
        float g1 = green(currentColor);
        float b1 = blue(currentColor);
        float r2 = red(trackColor);
        float g2 = green(trackColor);
        float b2 = blue(trackColor);
  
        float d = distSq(r1, g1, b1, r2, g2, b2); 
  
        if (d < threshold*threshold) {
  
          boolean found = false;
          for (Blob b : currentBlobs) {
            if (b.isNear(x, y)) {
              
              if (inputMode == 0) b.add(x, y, rawDepthData[loc]);
              else b.add(x, y);
              found = true;
              break;
            }
          }
  
          if (!found) {
            Blob b = new Blob(x, y, maxLife, distThreshold); // here we might need to add depth pixel data as well
            currentBlobs.add(b);
          }
        }
      }
    }
    
    // remove too small blobs
    for (int i = currentBlobs.size()-1; i >= 0; i--) {
      if (currentBlobs.get(i).size() < minBlobSize) {
        currentBlobs.remove(i);
      }
    }
  
    // There are no blobs!
    if (blobs.isEmpty() && currentBlobs.size() > 0) {
      if (debug) println("Adding blobs!");
      for (Blob b : currentBlobs) {
        b.id = blobCounter;
        blobs.add(b);
        blobCounter++;
      }
    } 
    else if (blobs.size() <= currentBlobs.size()) {
      // Match whatever blobs you can match
      for (Blob b : blobs) {
        float recordD = 1000;
        Blob matched = null;
        for (Blob cb : currentBlobs) {
          PVector centerB = b.getCenter();
          PVector centerCB = cb.getCenter();         
          float d = PVector.dist(centerB, centerCB);
          if (d < recordD && !cb.taken) {
            recordD = d; 
            matched = cb;
          }
        }
        matched.taken = true;
        b.become(matched);
      }
  
      // Whatever is leftover make new blobs
      for (Blob b : currentBlobs) {
        if (!b.taken) {
          b.id = blobCounter;
          blobs.add(b);
          blobCounter++;
        }
      }
    } 
    else if (blobs.size() > currentBlobs.size()) {
      for (Blob b : blobs) {
        b.taken = false;
      }
  
  
      // Match whatever blobs you can match
      for (Blob cb : currentBlobs) {
        float recordD = 1000;
        Blob matched = null;
        for (Blob b : blobs) {
          PVector centerB = b.getCenter();
          PVector centerCB = cb.getCenter();         
          float d = PVector.dist(centerB, centerCB);
          if (d < recordD && !b.taken) {
            recordD = d; 
            matched = b;
          }
        }
        if (matched != null) {
          matched.taken = true;
          // Resetting the lifespan here is no longer necessary since setting `lifespan = maxLife;` in the become() method in Blob.pde
          // matched.lifespan = maxLife;
          matched.become(cb);
        }
      }
  
      for (int i = blobs.size() - 1; i >= 0; i--) {
        Blob b = blobs.get(i);
        //b.lifetime++;
        if (!b.taken) {
          if (b.checkLife()) {
            blobs.remove(i);
          }
        }
      }
    }
    // update lifetime for all blobs
    /*
    for (Blob b : blobs) {
      b.lifetime = b.lifetime+1;
    }
    */
  }
  
  
  // retrieve image (trackerDataMap) from tracker
  PImage getTrackerImage(){
      trackerDataMap.updatePixels();
      return trackerDataMap;
  }
  
  
  // Draw all blobs
  void showBlobs(/*boolean showPixels*/){
    //println("showBlobs blobs size", blobs.size());
    for (Blob b : blobsFiltered) {
      b.show();
      //if (showPixels) b.showPixels();
    }
    //println();
  }
  
  void removeNestedBlobs(){
    Collections.sort(blobsFiltered); // sorts blobs by size, largest first
    for (int i = 0; i < blobsFiltered.size(); i++){
      for (int j = 0; j < blobsFiltered.size(); j++){
        if (i != j){
          if (blobsFiltered.get(i).isInside(blobsFiltered.get(j).minx, blobsFiltered.get(j).miny, blobsFiltered.get(j).maxx, blobsFiltered.get(j).maxy)){
            //println("Blob removed", "index", j, "id", blobs.get(j).id);
            //blobs.remove(j);
            blobsFiltered.get(j).nested = true; // flag for deletion
          }
          //else blobs.get(j).nested = false; // flag for deletion
        }  
      }
      
    }
    for (int i = blobsFiltered.size()-1; i > 0; i--){ // traverse in reverse and delete. In order to avoid errors due to list length changing while traversing.
      if (blobsFiltered.get(i).nested) {
        //getBlobFromId(blobsFiltered.get(i).id).lifetime = 0;
        blobsFiltered.remove(i);
      }
    }
  }
  
  /*
  // not ready for use
  void removeNewBlobs(){
    println();
    for (int i = blobsFiltered.size()-1; i > 0; i--){
      //blobsFiltered.get(i).lifetime = blobsFiltered.get(i).lifetime +1;
      print("ID", blobsFiltered.get(i).id, "Lifetime", blobsFiltered.get(i).lifetime);
      if (blobsFiltered.get(i).lifetime < 50) {
        //println("remove new blob with id", blobsFiltered.get(i).id, "and lifetime", blobsFiltered.get(i).lifetime);
        print(" REMOVED");
        blobsFiltered.remove(i);
      }
      println();
      //if (blobs.get(i).lifetime < 20) blobs
      //if (blobs.get(i).maxLife - blobs.get(i).lifespan < 10) blobs.remove(i); 
    }
  }
  */
  
  // checks if a given pixel is in a ignore area
  boolean isIgnored(int x, int y){
      for (Area a : ignoreAreas){
        if (distSq(a.x, a.y, x, y) < a.radius*a.radius) return true;  
      }
      return false;
  }
  
  // drasw ignore areas
  void showIgnoreAreas(){
    for (Area ia : ignoreAreas){
      ia.show();
    }
  }
  
  
  // --- GETTERS, SETTERS, CONTROLS, SETTINGS ---
  
  Blob [] getBlobs(){
    // use filters here
    Blob[] array = new Blob[t.blobsFiltered.size()];
    array = t.blobsFiltered.toArray(array);
    if (!nestedBlobsFilter) {
      array = new Blob[t.blobs.size()];
      array = t.blobs.toArray(array);
    }
    return array;
  }
  
  void setThreshold(float threshold_){
    threshold = threshold_;
  }
  
  float getThreshold(){
    return threshold;
  }
  
  void increaseThreshold(int step){
    threshold += step;
  }
  void decreaseThreshold(int step){
    threshold -= step;
  }
  
  void setDistThreshold(float distThreshold_){
    distThreshold = distThreshold_;
    for (int i = 0; i < blobs.size(); i++){
      blobs.get(i).distThreshold = distThreshold;
    }
  }
  
  float getDistThreshold(){
    return distThreshold;
  }
  
  void increaseDistThreshold(int step){
    distThreshold += step;
  }
  void decreaseDistThreshold(int step){
    distThreshold -= step;
  }
  
  
  int getMinDepth(){
    return minDepth;
  }
  int getMaxDepth(){
    return maxDepth;
  }
  
  void setMinDepth(int minDepth_){
    minDepth = constrain(minDepth_, 0, maxDepth);
  }
  void setMaxDepth(int maxDepth_){
    maxDepth = constrain(maxDepth_, minDepth, 2047);
  }
  
  void increaseMinDepth(int step){
    minDepth = constrain(minDepth+step, 0, maxDepth);
  }
  void decreaseMinDepth(int step){
    minDepth = constrain(minDepth-step, 0, maxDepth);
  }
  
  void increaseMaxDepth(int step){
    maxDepth = constrain(maxDepth+step, minDepth, 2047);
  }
  void decreaseMaxDepth(int step){
    maxDepth = constrain(maxDepth-step, minDepth, 2047);
  }
  
  void setTrackColor(color c){
    trackColor = c;
  }
  color getTrackColor(){
    return trackColor;
  }
  void increaseMinBlobSize(int step){
    minBlobSize+=step;
  }
  void decreaseMinBlobSize(int step){
    minBlobSize-=step;
  }
  int getMinBlobSize(){
    return minBlobSize;
  }
  void setMinBlobSize(int size){
    minBlobSize = size;
  }
  
  // add area to be ignored by tracker
  void addIgnoreArea(int x, int y, int radius){
    ignoreAreas.add(new Area(x, y, radius));  
  }
  // delete ignore area
  void deleteIgnoreArea(int x, int y){
    for (int i = 0; i < ignoreAreas.size(); i++){
      if (ignoreAreas.get(i).isInside(x, y)) {
        ignoreAreas.remove(i);
      }
    }
  }
  
  int getNrOfBlobs(){
    if (nestedBlobsFilter) return blobsFiltered.size();
    else return blobs.size();
  }
  
  // clear all ingore areas in the list
  void clearIgnoreAreas(){
    ignoreAreas.clear();  
  }
  
  // gives string version of ignoreAreas list
  String ignoreAreasToString(){
    String output = "";
    for (Area a : t.ignoreAreas){ // ### make ignoreAreasToString() inside tracker class instead
      output += "|"+a.x+","+a.y+","+a.radius;
    }
    return output;
  }
  
  void printBlobsList(){
    for (Blob b : blobs){
      println(b.getCenter().x, b.getCenter().y, b.id, b.size());
    }
  }
  
  ArrayList<Blob> copyBlobsList(){
    ArrayList<Blob> blobsList = new ArrayList<Blob>();
    for (Blob b : blobs){
      blobsList.add(b.getCopy());
    }
    return blobsList;
  }
  
  
  Blob getBlobFromId(int id_){
    for (Blob b : blobs){
      if (id_ == b.id) return b;
    }
    return null;
  }
  
  void setNestedBlobFilter(boolean nestedBlobsFilter_){
    nestedBlobsFilter = nestedBlobsFilter_;
  }
  
  boolean getNestedBlobFilter(){
    return nestedBlobsFilter;
  }
}
