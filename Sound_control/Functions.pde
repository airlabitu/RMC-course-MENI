// SOUND AREAS
int pressX, pressY;
int releaseX, releaseY;
int dragState = -1;

String nextID = "";


void oscEvent(OscMessage theOscMessage) {
  println("--- OSC MESSAGE RECEIVED ---");
  // Check if the address pattern is the right one
  if (theOscMessage.checkAddrPattern("/Blobs|X|Y|MIN_DEPTH|ID|NR_OF_PIXELS|")==true) {
    println("AddressPattern matched:", theOscMessage.addrPattern());
    // check if the typetag is the right one
    String typeTag = "";
    for (int i = 0; i < theOscMessage.typetag().length(); i++) typeTag += "i";
    if (theOscMessage.checkTypetag(typeTag)) {
      println("TypeTag matched:", theOscMessage.typetag());
      blobs = new Blob[theOscMessage.typetag().length()/5];
      println("Blobs length: ", blobs.length);
      for (int i = 0, j = 0; i <= theOscMessage.typetag().length()-5; i+=5, j++) {
        int x, y, blobMinDepth, id, nrOfPixels__;
        x = theOscMessage.get(i).intValue();
        y = theOscMessage.get(i+1).intValue();
        blobMinDepth = theOscMessage.get(i+2).intValue();
        id = theOscMessage.get(i+3).intValue();
        nrOfPixels__ = theOscMessage.get(i+4).intValue();

        blobs[j] = new Blob(x, y, blobMinDepth, id, nrOfPixels__);
        println("X: ", x, "Y: ", y, "Min Depth", blobMinDepth, "ID: ", id, "Pixels: ", nrOfPixels__);
      }
      framesSinceLastOscMessage = 0;
    }
  }
  println("----------------------------");
  println();
}

void mouseInteraction(Sphere s, ArrayList<Sphere> s_array, String type) {
  fill(0, 255, 0);
  ellipse(mouseX, mouseY, 20, 20);
  int d = (int)dist(mouseX, mouseY, s.x, s.y);
  soundManipulation(s, s_array, d, type);
}

void blobsInteraction(Sphere s, ArrayList<Sphere> s_array, String type) {
  if (framesSinceLastOscMessage > 25) {
    blobs = null;

    s.vol.setVal(s.vol.getMin(), millisToFadeNoBlobs);
  }
  if (blobs != null) {
    int minDist = 999999999;
    for (Blob b : blobs) {
      if (b != null) {
        int thisDist = (int)dist(b.x, b.y, s.x, s.y);
        if (thisDist < minDist) minDist = thisDist; 

        fill(map(b.minDepth, 0, 2047, 255, 0));
        ellipse(b.x, b.y, 50, 50);
      }
    }
    if (minDist != 999999999) {
      soundManipulation(s, s_array, minDist, type);
    }
  }
  framesSinceLastOscMessage++;
}

void soundManipulation(Sphere s, ArrayList<Sphere> s_array, int dist, String type) {
  // turn off
  float borderOne = 0.6; // border where sinus fade is ended
  float borderTwo = 0.3; // border where the linear fade is at a max
  noFill();
  if (type.equals("SINUS_FADE")){
    circle(s.x, s.y, (s.radius*borderOne)*2);
  }
  circle(s.x, s.y, (s.radius*borderTwo)*2);
  if (dist < s.radius) {
    // control sphere 's'
    if (type.equals("SINUS_FADE")) s.vol.setVal(sin(map(constrain(dist, s.radius*borderOne, s.radius), s.radius*borderOne, s.radius, 0, PI))*s.vol.getMax(), millisToFadeInside);   // shift over 100 millis      
    else if (type.equals("LINEAR_FADE")) s.vol.setVal(map(constrain(dist, s.radius*borderTwo, s.radius), s.radius*borderTwo, s.radius, s.vol.getMax(), s.vol.getMin()), millisToFadeInside);   // shift over 100 millis
    
    // GROUPS
    if (groupsEnabled){
      for (Sphere sp : s_array){ // groups  
        // set all others like id '5'
        if (s.getId() == 5){
          if (s.getId() != sp.getId()){
            sp.vol.setVal(s.vol.getVal(), millisToFadeInside);
            if (sp.rateEnabled) sp.rate.setVal(map(constrain(dist, s.radius*borderTwo, s.radius), s.radius*borderTwo, sp.radius, sp.rate.getMax(), sp.rate.getMin()), millisToFadeInside); 
          }
        }
        // control all in group with sphere 's' like it
        else if (s.getId() != sp.getId() && s.getGroup() == sp.getGroup()){
          sp.vol.setVal(s.vol.getVal(), millisToFadeInside);
          if (sp.rateEnabled) sp.rate.setVal(map(constrain(dist, s.radius*borderTwo, s.radius), s.radius*borderTwo, sp.radius, sp.rate.getMax(), sp.rate.getMin()), millisToFadeInside); 
          
        }
      }
    }
    
    //if (s.delayEnabled) s.delayVal.setVal(map(dist, 0, s.radius, s.delayVal.getMax(), s.delayVal.getMin()), millisToFadeInside);
    if (s.rateEnabled) s.rate.setVal(map(constrain(dist, s.radius*borderTwo, s.radius), s.radius*borderTwo, s.radius, s.rate.getMax(), s.rate.getMin()), millisToFadeInside); 
  }
  else {
    s.vol.setVal(s.vol.getMin(), millisToFadeOutside); // shift to min
    //if (s.delayEnabled) s.delayVal.setVal(s.delayVal.getMin(), millisToFadeOutside); 
    if (s.rateEnabled) s.rate.setVal(s.rate.getMin(), millisToFadeOutside);
  }
}

// key for toggling mouse simulation
void keyPressed() {
  if (key == 's') simulate = !simulate;
  if (key == '0' || key == '1' || key == '2' || key == '3' || key == '4' || key == '5' || key == '6' || key == '7' || key =='8' || key == '9'){
    nextID += key;
  }
  else if (keyCode == BACKSPACE && nextID.length() > 0) nextID = nextID.substring(0, nextID.length()-1); //nextID = nextID.substring(nextID.length()-1, nextID.length()); 
}

void mousePressed() {
  if (mouseButton == LEFT && placingSpheres) {
    pressX = mouseX;
    pressY = mouseY;
    releaseX = mouseX; // make release the same as press to clear old data
    releaseY = mouseY;
    dragState = 0;
  }
}

void mouseDragged() {
  if (mouseButton == LEFT && placingSpheres) {
    releaseX = mouseX;
    releaseY = mouseY;
    dragState = 1;
  }
}

void mouseReleased() {
  if (mouseButton == LEFT && placingSpheres){
    if (dragState == 1 && dist(pressX, pressY, releaseX, releaseY) > 5 && nextID.length() > 0) {
      Sphere s = new Sphere(pressX, pressY, int(dist(pressX, pressY, releaseX, releaseY)), null, this, int(nextID), 1);
      s.vol.setVal(s.vol.getMin(), millisToFadeOutside);
      spheres.add(s);
      nextID = "";
      
      
      //t.addIgnoreArea(pressX, pressY, int(dist(pressX, pressY, releaseX, releaseY)));
      //t.ignoreAreas.add(new Area(pressX, pressY, int(dist(pressX, pressY, releaseX, releaseY)))); // move inside tracker class
      dragState = 2;
    }
  }
  else if (mouseButton == RIGHT && placingSpheres) {
    for (int i = 0; i < spheres.size(); i++){
      if (dist(mouseX, mouseY, spheres.get(i).x, spheres.get(i).y) < spheres.get(i).radius) {
        spheres.remove(i);
      }
    }
  }
}

void showIgnoreCircle() {
  if (!mousePressed) return; // no need to draw if the mouse isn't pressed
  noFill();
  if (dragState == 0 || dragState == 1) {
    stroke(0, 255, 0);
    float size = max(5, dist(pressX, pressY, releaseX, releaseY));
    circle(pressX, pressY, size*2);
  }
}
