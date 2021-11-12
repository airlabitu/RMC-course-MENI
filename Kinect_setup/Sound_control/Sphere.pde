class Sphere{
  int x, y, radius, xMove, yMove;
  SoundFile track;
  float targetVol;
  float volIncrement;
  float incrementDir = 0;
  ValueFader vol;
  ValueFader delayVal;
  int group;
  int id;
  Delay delay;
  boolean delayEnabled;
  boolean envelopeEnabled;
  boolean rateEnabled;
  ValueFader rate;
  
  Sphere(int x_, int y_, int radius_, String track_, PApplet pa_, int id_, int group_){
    x = x_;
    y = y_;
    radius = radius_;
    if (track != null) track = new SoundFile(pa_, track_);
    //else println("TRACK null");
    vol = new ValueFader();
    vol.setMinMax(0.00001,1);
    delayVal = new ValueFader();
    delayVal.setMinMax(0.3, 0.8); 
    rate = new ValueFader();
    rate.setMinMax(0.6, 1.0);
    id = id_;
    group = group_;
  }
  
  void enableDelay(PApplet pa_, float tape_){
    delay = new Delay(pa_);
    delay.process(track, tape_);
    delayEnabled = true;
  }
  
  void enableRate(){
    rateEnabled = true;
  }
  
  void update(){
    vol.update();
    if (track != null) track.amp(vol.getVal());
    if (delayEnabled) {
      delayVal.update();
      delay.feedback(delayVal.getVal());
    }
    if (rateEnabled) {
      rate.update();
      if (track != null) track.rate(rate.getVal());
    }
  }
  
  void show(int red, int green, int blue){
    noFill();
    if (vol.getVal() > vol.getMin()) fill(red, green, blue, map(vol.getVal(), vol.getMin(), vol.getMax(), 0, 150));
    stroke(255);
    ellipse(x, y, radius*2, radius*2);
    fill(0,255,0);
    if (rateEnabled) text("Rate: " + nf(rate.getVal(), 0, 2), x+xMove, y-30+yMove);
    if (delayEnabled) text("Delay: " + nf(delayVal.getVal(), 0, 2), x+xMove, y-15+yMove);
    text("Vol: " + nf(vol.getVal(), 0, 2), x+xMove, y+yMove);
    text("ID: " + id, x+xMove-30, y+30+yMove);    
    //text("Group: " + group, x+xMove+30, y+30+yMove); 
  
  }
  
  int getGroup(){
    return group;
  }
  
  int getId(){
    return id;
  }
}
