import processing.core.*; 
import processing.data.*; 
import processing.event.*; 
import processing.opengl.*; 

import processing.video.*; 
import boofcv.processing.*; 
import java.util.*; 
import georegression.struct.shapes.Polygon2D_F64; 
import georegression.struct.point.Point2D_F64; 
import boofcv.alg.fiducial.qrcode.QrCode; 
import themidibus.*; 
import java.util.*; 

import java.util.HashMap; 
import java.util.ArrayList; 
import java.io.File; 
import java.io.BufferedReader; 
import java.io.PrintWriter; 
import java.io.InputStream; 
import java.io.OutputStream; 
import java.io.IOException; 

public class ObjectTracker_v3 extends PApplet {

// ToDo
// move midi mapped values outside qr object
// make mapping code coherent
// write better comments
// implement OSC option
// rename QR class etc.







          // library for Midi communication


MidiBus myBus; // MIDI object for sending MIDI to Ableton Live

Capture cam;
//SimpleQrCode detector;
SimpleFiducial detector;

HashMap<String,QRObject> QRObjects = new HashMap<String,QRObject>();

int trackingCenterX, trackingCenterY;
int maxDist;
boolean sendMIDI = true;

public void setup() {
  // Open up the camera so that it has a video feed to process
  initializeCamera(PApplet.parseInt(1920/2), PApplet.parseInt(1080/2));
  surface.setSize(cam.width, cam.height);
  detector = Boof.fiducialSquareBinaryRobust(0.1f);
  //detector = Boof.fiducialSquareBinary(0.1,100);
  detector.guessCrappyIntrinsic(cam.width,cam.height);
  
   
  
  // set tracking area origin
  trackingCenterX = cam.width/2;
  trackingCenterY = cam.height/2;
  
  //detector = Boof.detectQR();
  
  myBus = new MidiBus(this, -1, "Bus 1"); // Create a new MidiBus with no input device and "Bus 1" as the output device.
  
  maxDist = (int)dist(trackingCenterX, trackingCenterY, width, height);
}

public void draw() {
  if (cam.available() == true) {
    cam.read();

    List<FiducialFound> found = detector.detect(cam);

    image(cam, 0, 0);
    
    String QR_info = "";
    
    for( FiducialFound fiducial : found ) {
      println("FS: ", found.size());
      float angle;
      int x, y;
      int id;
      
      // get ID
      id = (int)fiducial.getId();
      //if (id == 1) return; // to prevent it from failing when adding id 1 by mistake in beginning of program
      // getting fiducials center coordinate
      x = (int)fiducial.getImageLocation().getX();
      y = (int)fiducial.getImageLocation().getY();
      
      // calculating angle
      if (fiducial.getFiducialToCamera().getR().getData()[1] < 0){
        angle = map((float)fiducial.getFiducialToCamera().getR().getData()[0], 1, -1, 0, 180);
      }
      else {
        angle = map((float)fiducial.getFiducialToCamera().getR().getData()[0], -1, 1, 180, 360);
      }
      
      //if (fiducial.bounds.size() == 4){
        
      if (!QRObjects.containsKey(""+id)) QRObjects.put(""+id, new QRObject(id)); // add qr object if not already existing
      //if (!QRObjects.containsKey(id)) QRObjects.put(qr.message, new QRObject(int(qr.message))); // add qr object if not already existing
                
        //Point2D_F64 p0 = qr.bounds.get(0);
        //Point2D_F64 p1 = qr.bounds.get(1);
        //Point2D_F64 p2 = qr.bounds.get(2);
        //Point2D_F64 p3 = qr.bounds.get(3);
        
        QRObject QR_obj = QRObjects.get(""+id);
        
        // send midi 'on' messages
        if (!QR_obj.isActive) {
          QR_obj.isActive = true;
          if (sendMIDI) myBus.sendControllerChange(0, id+3, 127); // send midi data parameter order (channel, number, value)
        }
        
        QR_obj.framesSinceActive = 0;
        
        QR_obj.x = x;
        QR_obj.y = y;
        QR_obj.setSelfRotation((int)angle);
        
        QR_obj.trackingCenterRotation = (int)getRotation(QR_obj.x, QR_obj.y, trackingCenterX, trackingCenterY);
        QR_obj.trackingCenterRotation = constrain((int)map(QR_obj.trackingCenterRotation, 0, 359, 0, 127), 0, 127); // mapping value to MIDI scale
        QR_obj.trackingCenterDistance = (int)dist(QR_obj.x, QR_obj.y, trackingCenterX, trackingCenterY);
        QR_obj.trackingCenterDistance = constrain((int)map(QR_obj.trackingCenterDistance, 0, maxDist, 0, 127), 0, 127);
        
        // send out midi
        if (sendMIDI){
          myBus.sendControllerChange(0, id, QR_obj.trackingCenterRotation); // send midi data parameter order (channel, number, value)
          myBus.sendControllerChange(0, id+1, QR_obj.trackingCenterDistance); // send midi data parameter order (channel, number, value)
          myBus.sendControllerChange(0, id+2, QR_obj.midiRotationVal); // send midi data parameter order (channel, number, value)
          /*
          println(id, QR_obj.trackingCenterRotation);
          println(id+1, QR_obj.trackingCenterDistance);
          println(id+2, QR_obj.midiRotationVal);
          println();
          */
        }
        // draw QR marker tracking data
        
        
      // visualize
      fill(255, 0, 255);
      textSize(20);
      ellipse(x, y, 10, 10);
      text("angle: " + (int)angle +"\nid: " + id, x+40, y);
      
        
      QR_info += "\nID: " + id + "\nGlobal rotation: " + QR_obj.trackingCenterRotation + "\nDist to center: " + QR_obj.trackingCenterDistance + "\nOwn rotation: " + QR_obj.midiRotationVal + "\non/off: " + QR_obj.isActive + "\non/off fade: " + QR_obj.isActiveFade + "\n\n";

        //QR_info += "\nID: " + qr.message + "\n" + "Own angle: " + QR_obj.angle + " move: " + QR_obj.angleMove + " rotation: " + QR_obj.rotationVal + " midi rotation: " + QR_obj.midiRotationVal + "\nGlobal rotation: " + QR_obj.trackingCenterRotation + "\nDist to center: " + QR_obj.trackingCenterDistance+"\n\n";
        //QR_info += "\nID: " + qr.message + "\nOwn rotation: " + mapped_QR_self_rotation + "\nGlobal rotation: " + mapped_trackingCenterRotation + "\nDist to center: " + mapped_trackingCenterDistance+"\n\n";

        
      //}
    }
    
    // change object activ states and send MIDI 'off' messages + 'on/off' fade messages
    for (Map.Entry me : QRObjects.entrySet()) {
      QRObject QR_obj = QRObjects.get(me.getKey());
      QR_obj.framesSinceActive++;
      
      if (QR_obj.framesSinceActive > 60 && QR_obj.isActive == true) {
        QR_obj.isActive = false;
        // send MIDI off message
        if (sendMIDI) myBus.sendControllerChange(0, QR_obj.id+3, 0); // send midi data parameter order (channel, number, value)
      }
      // send midi on/off fade message
      QR_obj.updateFade();
      if (sendMIDI) myBus.sendControllerChange(0, QR_obj.id+4, PApplet.parseInt(QR_obj.isActiveFade)); // send midi data parameter order (channel, number, value)
      //println(QR_obj.id, QR_obj.isActive, QR_obj.framesSinceActive, QR_obj.isActiveFade);
    }
    
    /*
    for (Map.Entry me : QRObjects.entrySet()) {
      QRObject QR_obj = QRObjects.get(me.getKey());
      QR_info += "\nID: " + QR_obj.id + "\nGlobal rotation: " + QR_obj.trackingCenterRotation + "\nDist to center: " + QR_obj.trackingCenterDistance + "\nOwn rotation: " + QR_obj.midiRotationVal + "\non/off: " + QR_obj.isActive + "\non/off fade: " + QR_obj.isActiveFade + "\n\n";
      //QR_obj.framesSinceActive++;
      
    }
    */
    
    fill(255);
    textSize(10);
    text(QR_info, 10, 0);
    textSize(15);
    text("FPS: " + (int)frameRate, width-70, 20);
    if (sendMIDI) fill(0, 255, 0);
    else fill(255, 0, 0);
    text("Sending MIDI: " + sendMIDI, width-145, height -10);
    noFill();
    strokeWeight(1);
    stroke(255, 0, 0);
    line(trackingCenterX-10, trackingCenterY, trackingCenterX+10, trackingCenterY);
    line(trackingCenterX, trackingCenterY-10, trackingCenterX, trackingCenterY+10);
    ellipse(trackingCenterX, trackingCenterY, maxDist*2, maxDist*2);
    
    //PImage img = cam;
    //img.getModifiedX2()
    
    
  }
}

public void initializeCamera( int desiredWidth, int desiredHeight ) {
  String[] cameras = Capture.list();
  for (int i = 0; i < Capture.list().length; i++){
    println(Capture.list()[i]);
  }
  
  if (cameras.length == 0) {
    println("There are no cameras available for capture.");
    exit();
  } else {
    String [] source = loadStrings("source.txt");
    
    cam = new Capture(this, desiredWidth, desiredHeight, Capture.list()[PApplet.parseInt(source[0])]);
    cam.start();
    
    
  }
}


// method that calculates rotation of one point around another
public float getRotation(float x1, float y1, float x2, float y2){
  
  PVector a = new PVector(x1, y1);   // point a
  PVector b = new PVector(x2, y2);   // point b
  PVector r = new PVector(0, -100);  // reference point
 
  b.sub(a);             // move point b
  a.sub(a);             // move point a
  
  // calculate rotation
  float angle = degrees(r.angleBetween(r,b));
  if (b.x < 0){ // turn result around if b is on the left side of a
    angle = 360 - angle;  
  }
  return angle; // return angle


}

public void keyReleased(){
  if (key == 'd') maxDist = (int)dist(trackingCenterX, trackingCenterY, mouseX, mouseY);
  if (key == 'm') sendMIDI = !sendMIDI;
  if (key == 'o') {
    trackingCenterX = mouseX;
    trackingCenterY = mouseY;
  }
}
class QRObject{
  
  float x;
  float y;
  
  int id;
  
  boolean isActive;
  
  float isActiveFade;
  float isActiverFadeStep;
  
  int framesSinceActive;
  
  int lastAngle;
  int angle;
  int angleMove;
  int midiAngle;
  
  int rotationVal;
  int midiRotationVal;
  
  PVector lastVector;
  PVector currentVector;
  
  int trackingCenterRotation;
  int trackingCenterDistance;
  

  QRObject(int id_){
    id = id_;
    
    lastAngle = -1;
    isActive = true;
    isActiveFade = 127;
    isActiverFadeStep = 2.5f;
    
    println("Object added: ", id);
    
  }
  
  public void setSelfRotation(int angle_){
    angle = angle_;
    
    if (lastAngle == -1) lastAngle = angle; // this alignes last and current for first call to the function for this object    
    
    lastVector = new PVector(0, -100);
    lastVector.rotate(radians(lastAngle));
    currentVector = new PVector(0, -100);
    currentVector.rotate(radians(angle));
  
    angleMove = PApplet.parseInt(degrees(lastVector.angleBetween(lastVector,currentVector))); // total rotational move
    
    if (angle < lastAngle) rotationVal = constrain(rotationVal + angleMove*3, 0, 359); // rotation one direction
    else if (angle > lastAngle) rotationVal = constrain(rotationVal - angleMove*3, 0, 359); // rotation the other direction
    midiRotationVal = PApplet.parseInt(map(rotationVal, 0, 359, 127, 0)); // map to midi
    
    lastAngle = angle;

  }
  
  public void updateFade(){
    if (isActive) isActiveFade = constrain(isActiveFade+isActiverFadeStep, 0, 127);
    else isActiveFade = constrain(isActiveFade-isActiverFadeStep, 0, 127);
  }

}
  static public void main(String[] passedArgs) {
    String[] appletArgs = new String[] { "ObjectTracker_v3" };
    if (passedArgs != null) {
      PApplet.main(concat(appletArgs, passedArgs));
    } else {
      PApplet.main(appletArgs);
    }
  }
}
