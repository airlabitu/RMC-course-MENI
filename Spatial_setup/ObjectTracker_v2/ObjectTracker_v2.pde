// ToDo
// move midi mapped values outside qr object
// make mapping code coherent
// write better comments
// make on/off midi message

import processing.video.*;
import boofcv.processing.*;
import java.util.*;
import georegression.struct.shapes.Polygon2D_F64;
import georegression.struct.point.Point2D_F64;
import boofcv.alg.fiducial.qrcode.QrCode;
import themidibus.*;          // library for Midi communication

MidiBus myBus; // MIDI object for sending MIDI to Ableton Live

Capture cam;
SimpleQrCode detector;

//ArrayList<QRObject> objects = new ArrayList<QRObject>();

HashMap<String,QRObject> QRObjects = new HashMap<String,QRObject>();

int trackingCenterX, trackingCenterY;
int maxDist;
boolean sendMIDI = true;

void setup() {
  // Open up the camera so that it has a video feed to process
  initializeCamera(1920/2, 1080/2);
  //initializeCamera(640, 480);
  surface.setSize(cam.width, cam.height);
  
  // set tracking area origin
  trackingCenterX = cam.width/2;
  trackingCenterY = cam.height/2;
  
  detector = Boof.detectQR();
  
  myBus = new MidiBus(this, -1, "Bus 1"); // Create a new MidiBus with no input device and "Bus 1" as the output device.
  
  maxDist = (int)dist(trackingCenterX, trackingCenterY, width, height);
}

void draw() {
  if (cam.available() == true) {
    cam.read();

    List<QrCode> found = detector.detect(cam);

    image(cam, 0, 0);
    
    
    String QR_info = "";

    for( QrCode qr : found ) {
      
      if (qr.bounds.size() == 4){
        
        if (!QRObjects.containsKey(qr.message)) QRObjects.put(qr.message, new QRObject(int(qr.message))); // add qr object if not already existing
                
        Point2D_F64 p0 = qr.bounds.get(0);
        Point2D_F64 p1 = qr.bounds.get(1);
        Point2D_F64 p2 = qr.bounds.get(2);
        Point2D_F64 p3 = qr.bounds.get(3);
        
        QRObject QR_obj = QRObjects.get(qr.message);
        
        QR_obj.x = ((float)p0.x + (float)p1.x + (float)p2.x + (float)p3.x) / 4;
        QR_obj.y = ((float)p0.y + (float)p1.y + (float)p2.y + (float)p3.y) / 4;
        QR_obj.setSelfRotation((int)getRotation((float)p0.x, (float)p0.y, (float)p1.x, (float)p1.y));
        
        QR_obj.trackingCenterRotation = (int)getRotation(QR_obj.x, QR_obj.y, trackingCenterX, trackingCenterY);
        QR_obj.trackingCenterRotation = constrain((int)map(QR_obj.trackingCenterRotation, 0, 359, 0, 127), 0, 127); // mapping value to MIDI scale
        QR_obj.trackingCenterDistance = (int)dist(QR_obj.x, QR_obj.y, trackingCenterX, trackingCenterY);
        QR_obj.trackingCenterDistance = constrain((int)map(QR_obj.trackingCenterDistance, 0, maxDist, 0, 127), 0, 127);
        
        // send out midi
        if (sendMIDI){
          myBus.sendControllerChange(0, int(qr.message), QR_obj.trackingCenterRotation); // send midi data parameter order (channel, number, value)
          myBus.sendControllerChange(0, int(qr.message)+1, QR_obj.trackingCenterDistance); // send midi data parameter order (channel, number, value)
          myBus.sendControllerChange(0, int(qr.message)+2, QR_obj.midiRotationVal); // send midi data parameter order (channel, number, value)
        }
        // draw QR marker tracking data
        
        strokeWeight(5);
        
        stroke(255, 0, 0);
        line((float)p0.x, (float)p0.y, (float)p1.x, (float)p1.y);
        stroke(0, 255, 0);
        line((float)p1.x, (float)p1.y, (float)p2.x, (float)p2.y);
        line((float)p2.x, (float)p2.y, (float)p3.x, (float)p3.y);
        line((float)p3.x, (float)p3.y, (float)p0.x, (float)p0.y);
        
        ellipse(QR_obj.x, QR_obj.y, 10, 10);
        //ellipse(QR_CenterX, QR_CenterY, 10, 10);
        
        textSize(15);
        fill(#FA05FF);
        text("0", (float)p0.x, (float)p0.y);
        text("1", (float)p1.x, (float)p1.y);
        stroke(0, 255, 255);
        strokeWeight(1);
        line(QR_obj.x, QR_obj.y, trackingCenterX, trackingCenterY);
        //line(QR_CenterX, QR_CenterY, trackingCenterX, trackingCenterY);
        
        QR_info += "\nID: " + qr.message + "\n" + "Own angle: " + QR_obj.angle + " move: " + QR_obj.angleMove + " rotation: " + QR_obj.rotationVal + " midi rotation: " + QR_obj.midiRotationVal + "\nGlobal rotation: " + QR_obj.trackingCenterRotation + "\nDist to center: " + QR_obj.trackingCenterDistance+"\n\n";
        //QR_info += "\nID: " + qr.message + "\nOwn rotation: " + mapped_QR_self_rotation + "\nGlobal rotation: " + mapped_trackingCenterRotation + "\nDist to center: " + mapped_trackingCenterDistance+"\n\n";

        
      }
    }
    
    
    fill(255);
    textSize(10);
    text(QR_info, 10, 0);
    textSize(15);
    if (sendMIDI) fill(0, 255, 0);
    else fill(255, 0, 0);
    text("Sending MIDI: " + sendMIDI, width-145, height -10);
    noFill();
    strokeWeight(1);
    stroke(255, 0, 0);
    line(trackingCenterX-10, trackingCenterY, trackingCenterX+10, trackingCenterY);
    line(trackingCenterX, trackingCenterY-10, trackingCenterX, trackingCenterY+10);
    ellipse(trackingCenterX, trackingCenterY, maxDist*2, maxDist*2);
    
  }
}

void initializeCamera( int desiredWidth, int desiredHeight ) {
  String[] cameras = Capture.list();
  for (int i = 0; i < Capture.list().length; i++){
    println(Capture.list()[i]);
  }
  
  if (cameras.length == 0) {
    println("There are no cameras available for capture.");
    exit();
  } else {
    cam = new Capture(this, desiredWidth, desiredHeight, Capture.list()[0]);
    cam.start();
  }
}


// method that calculates rotation of one point around another
float getRotation(float x1, float y1, float x2, float y2){
  
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

void keyReleased(){
  if (key == 'd') maxDist = (int)dist(trackingCenterX, trackingCenterY, mouseX, mouseY);
  if (key == 'm') sendMIDI = !sendMIDI;
  if (key == 'o') {
    trackingCenterX = mouseX;
    trackingCenterY = mouseY;
  }
}
