// ToDo
// make use of real GUI elements
// make auto save/load of settings
// make new midi mapper


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

int trackingCenterX = 320, trackingCenterY = 240;
int maxDist;
boolean sendMIDI = true;

void setup() {
  // Open up the camera so that it has a video feed to process
  initializeCamera(640, 480);
  surface.setSize(cam.width, cam.height);


  detector = Boof.detectQR();
  
  myBus = new MidiBus(this, -1, "Bus 1"); // Create a new MidiBus with no input device and "Bus 1" as the output device.

  
  maxDist = (int)dist(trackingCenterX = 320, trackingCenterY = 240, width, height);
}

void draw() {
  if (cam.available() == true) {
    cam.read();

    List<QrCode> found = detector.detect(cam);

    image(cam, 0, 0);
    
    
    String QR_info = "";

    for( QrCode qr : found ) {
      
      if (qr.bounds.size() == 4){
        Point2D_F64 p0 = qr.bounds.get(0);
        Point2D_F64 p1 = qr.bounds.get(1);
        Point2D_F64 p2 = qr.bounds.get(2);
        Point2D_F64 p3 = qr.bounds.get(3);
        
        float QR_CenterX = ((float)p0.x + (float)p1.x + (float)p2.x + (float)p3.x) / 4;
        float QR_CenterY = ((float)p0.y + (float)p1.y + (float)p2.y + (float)p3.y) / 4;
        int QR_self_rotation = (int)getRotation((float)p0.x, (float)p0.y, (float)p1.x, (float)p1.y);
        int mapped_QR_self_rotation = constrain((int)map(QR_self_rotation, 0, 359, 0, 127), 0, 127);
        int trackingCenterRotation = (int)getRotation(QR_CenterX, QR_CenterY, trackingCenterX, trackingCenterY);
        int mapped_trackingCenterRotation = constrain((int)map(trackingCenterRotation, 0, 359, 0, 127), 0, 127);
        int trackingCenterDistance = (int)dist(QR_CenterX, QR_CenterY, trackingCenterX, trackingCenterY);
        int mapped_trackingCenterDistance = constrain((int)map(trackingCenterDistance, 0, maxDist, 0, 127), 0, 127);
        
        // send out midi
        if (sendMIDI){
          myBus.sendControllerChange(0, int(qr.message), mapped_trackingCenterRotation); // send midi data parameter order (channel, number, value)
          myBus.sendControllerChange(0, int(qr.message)+1, mapped_trackingCenterDistance); // send midi data parameter order (channel, number, value)
          myBus.sendControllerChange(0, int(qr.message)+2, mapped_QR_self_rotation); // send midi data parameter order (channel, number, value)
        }
        // draw QR marker tracking data
        
        strokeWeight(5);
        
        stroke(255, 0, 0);
        line((float)p0.x, (float)p0.y, (float)p1.x, (float)p1.y);
        stroke(0, 255, 0);
        line((float)p1.x, (float)p1.y, (float)p2.x, (float)p2.y);
        line((float)p2.x, (float)p2.y, (float)p3.x, (float)p3.y);
        line((float)p3.x, (float)p3.y, (float)p0.x, (float)p0.y);
        
        ellipse(QR_CenterX, QR_CenterY, 10, 10);
        
        textSize(15);
        fill(#FA05FF);
        text("0", (float)p0.x, (float)p0.y);
        text("1", (float)p1.x, (float)p1.y);
        stroke(0, 255, 255);
        strokeWeight(1);
        line(QR_CenterX, QR_CenterY, trackingCenterX, trackingCenterY);
        
        QR_info += "\nID: " + qr.message + "\nOwn rotation: " + mapped_QR_self_rotation + "\nGlobal rotation: " + mapped_trackingCenterRotation + "\nDist to center: " + mapped_trackingCenterDistance+"\n\n";
        
      }
    }
    
    
    fill(255);
    textSize(10);
    text(QR_info, 10, 0);
    textSize(15);
    text("Sending MIDI: " + sendMIDI, width-145, height -10);
    noFill();
    strokeWeight(1);
    stroke(255, 0, 0);
    ellipse(trackingCenterX, trackingCenterY, 5, 5);
    ellipse(trackingCenterX, trackingCenterY, maxDist*2, maxDist*2);
    
  }
}

void initializeCamera( int desiredWidth, int desiredHeight ) {
  String[] cameras = Capture.list();

  if (cameras.length == 0) {
    println("There are no cameras available for capture.");
    exit();
  } else {
    cam = new Capture(this, desiredWidth, desiredHeight);
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
  if (key == 'd') maxDist = (int)dist(trackingCenterX = 320, trackingCenterY = 240, mouseX, mouseY);
  if (key == 'm') sendMIDI = !sendMIDI;
}
