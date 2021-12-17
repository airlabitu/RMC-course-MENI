// ToDo
// move midi mapped values outside qr object
// make mapping code coherent
// write better comments
// implement OSC option
// rename QR class etc.

import processing.video.*;
import boofcv.processing.*;
import java.util.*;
import georegression.struct.shapes.Polygon2D_F64;
import georegression.struct.point.Point2D_F64;
import boofcv.alg.fiducial.qrcode.QrCode;
import themidibus.*;          // library for Midi communication
import java.util.*;

MidiBus myBus; // MIDI object for sending MIDI to Ableton Live

Capture cam;
//SimpleQrCode detector;
SimpleFiducial detector;

HashMap<String, QRObject> QRObjects = new HashMap<String, QRObject>();

int trackingCenterX, trackingCenterY;
int maxDist;
boolean sendMIDI = true;

void setup() {
  // Open up the camera so that it has a video feed to process
  initializeCamera(int(1920/2), int(1080/2));
  surface.setSize(cam.width, cam.height);
  detector = Boof.fiducialSquareBinaryRobust(0.1);
  //detector = Boof.fiducialSquareBinary(0.1,100);
  detector.guessCrappyIntrinsic(cam.width, cam.height);



  // set tracking area origin
  trackingCenterX = cam.width/2;
  trackingCenterY = cam.height/2;

  //detector = Boof.detectQR();

  myBus = new MidiBus(this, -1, "RMC"); // Create a new MidiBus with no input device and "Bus 1" as the output device.

  maxDist = (int)dist(trackingCenterX, trackingCenterY, width, height);
}

void draw() {
  if (cam.available() == true) {
    cam.read();

    List<FiducialFound> found = detector.detect(cam);

    image(cam, 0, 0);

    String QR_info = "";

    for ( FiducialFound fiducial : found ) {
      println("FS: ", found.size());
      float angle;
      int x, y;
      int id;

      // get ID
      id = (int)fiducial.getId();
      //if (id == 1) return; // to prevent it from failing when adding id 1 by mistake in beginning of program
      // getting fiducials center coordinate
      x = width-(int)fiducial.getImageLocation().getX();
      y = (int)fiducial.getImageLocation().getY();

      // calculating angle
      if (fiducial.getFiducialToCamera().getR().getData()[1] < 0) {
        angle = map((float)fiducial.getFiducialToCamera().getR().getData()[0], 1, -1, 0, 180);
      } else {
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
      if (sendMIDI) {
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
      if (sendMIDI) myBus.sendControllerChange(0, QR_obj.id+4, int(QR_obj.isActiveFade)); // send midi data parameter order (channel, number, value)
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

void initializeCamera( int desiredWidth, int desiredHeight ) {
  String[] cameras = Capture.list();
  for (int i = 0; i < Capture.list().length; i++) {
    println(Capture.list()[i]);
  }

  if (cameras.length == 0) {
    println("There are no cameras available for capture.");
    exit();
  } else {
    String [] source = loadStrings("source.txt");

    cam = new Capture(this, desiredWidth, desiredHeight, Capture.list()[1]);
    cam.start();
  }
}


// method that calculates rotation of one point around another
float getRotation(float x1, float y1, float x2, float y2) {

  PVector a = new PVector(x1, y1);   // point a
  PVector b = new PVector(x2, y2);   // point b
  PVector r = new PVector(0, -100);  // reference point

  b.sub(a);             // move point b
  a.sub(a);             // move point a

  // calculate rotation
  float angle = degrees(r.angleBetween(r, b));
  if (b.x < 0) { // turn result around if b is on the left side of a
    angle = 360 - angle;
  }
  return angle; // return angle
}

void keyReleased() {
  if (key == 'd') maxDist = (int)dist(trackingCenterX, trackingCenterY, mouseX, mouseY);
  if (key == 'm') sendMIDI = !sendMIDI;
  if (key == 'o') {
    trackingCenterX = mouseX;
    trackingCenterY = mouseY;
  }
}
