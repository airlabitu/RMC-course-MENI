// This code is made by Halfdan Hauch Jensen (halj@itu.dk) at AIR LAB ITU
// The code is using Daniel Shiffmans blob detection class, with a few alterations.

// Daniel Shiffman
// http://codingtra.in
// http://patreon.com/codingtrain
// Code for: https://youtu.be/o1Ob28sF0N8


// ToDo
  // Tjek og implementer bedre performance - e.g. clear video/kinect/video objekter efter mode change

import processing.video.*;
import org.openkinect.freenect.*;
import org.openkinect.processing.*;
import oscP5.*;
import netP5.*;
import java.util.*;
 
Kinect kinect;
Movie simulationVideo;
Capture webCam;

Tracker t = new Tracker();

OscP5 oscP5_primary;
OscP5 oscP5_secondary;
NetAddress myRemoteLocation_primary;
NetAddress myRemoteLocation_secondary;

String [] oscInfo_primary;
String [] oscInfo_secondary;

String logFile = "kinect_log_.txt";
boolean logsEnabled = true; // set insettings file
boolean exit_on_kinect_error = true; // set insettings file
boolean debug = false; // only set in code
int noKinectFrameCount; // 
long kinectFrameZero;
boolean kinectRebootAttempted = false; 
boolean closeDownFlag = false;
long closeDownTime = 0;

boolean webcamDetected = false;

OscAlertProsponer kinectAlertProsponer; // email alert prosponer

void setup() {
  size(640, 480);
  frameRate(25);
  if (logsEnabled) log("------------------", logFile);
  if (logsEnabled) log("Starting up sketch", logFile);
  loadSettings("data/default_settings.txt"); // load default settings from file
  if (debug) {
    println("exit_on_kinect_error:", exit_on_kinect_error);
    println("logsEnabled:", logsEnabled);
    println("disableSimulation:", disableSimulation);
  }
  
  // email alert prosponer
  kinectAlertProsponer = new OscAlertProsponer(new OscP5(this, 22022), "127.0.0.1", 11011, "/KinectAlive");
  kinectAlertProsponer.isActive = true; // tris setting could be set in the settings file
}


void draw() {
  if (closeDownFlag) { 
    if (millis() > closeDownTime){
      if (logsEnabled) log("closing down", logFile);
      if (debug) println("closing down");
    exit();
    }
  }
  
  else{
    if (inputMode == 0) {
      if (kinect != null && kinect.numDevices() != 0) {
        noKinectFrameCount = 0;
        if (kinectFrameZero/*frameCount*/ > 10){ // catch kinect data failed at start up
          if (kinect.getRawDepth()[0] == 0 && kinectFrameZero < 20) {  // kinect data failed
            errorString = "Kinect data failed";
            if (logsEnabled) log(errorString, logFile);
            if (debug) println(errorString);
            if (kinectFrameZero == 11/*!kinectRebootAttempted*/){ // try rebooting if not already tried
              if (logsEnabled) log("Rebooting kinect", logFile);
              if (debug) println("Rebooting kinect");
              setInputMode(inputMode); // reboot kinect
            }
            else if (kinectFrameZero == 19){ // failed at reconnecting! - do: warnings, logs, closedown
              if (logsEnabled) log("reboot unsuccesfull", logFile);
              if (debug) println("reboot unsuccesfull");
              if (exit_on_kinect_error){
                if (logsEnabled) log("Closing down in 10 sec, try relaunching the sketch", logFile);
                if (debug) println("Closing down in 10 sec, try relaunching the sketch");
                closeDownFlag = true;
                closeDownTime = millis()+10000;
              }
                //else if (frameCount == 19) setInputMode(inputMode); // try again if exit_on_kinect_error closedown disabled          
            }
          }
          else t.detectBlobs(kinect.getRawDepth()); 
        }
      }
      else { // no kinect error
        errorString = "No Kinect connected";
        noKinectFrameCount++;
        if (noKinectFrameCount == 1 && logsEnabled) log(errorString, logFile);
        if (debug && noKinectFrameCount == 1) println(errorString);
        
        if (noKinectFrameCount == 1 && exit_on_kinect_error){
          if (logsEnabled) log("Closing down in 10 sec, try relaunching the sketch", logFile);
          if (debug) println("Closing down in 10 sec, try relaunching the sketch");
          closeDownFlag = true;
          closeDownTime = millis()+10000;
        }
      }
      kinectFrameZero++;
    }
    else if (inputMode == 1){
      if(webCam != null){
        if (webCam.available()){
          webCam.read();
          t.detectBlobs(webCam);
        }
      }
    }
    else if (inputMode == 2 && !disableSimulation) t.detectBlobs(simulationVideo);
    
    if (sendingOSC && t.getNrOfBlobs() > 0) sendBlobsOsc(); // send blobs over OSC if there is any blobs to send
    
    if (disableSimulation && inputMode == 2) {
      background(255,0,0);
      errorString = "Simulation disabled";
    }
    else if (!webcamDetected && inputMode == 1){
      background(255,0,0);
      errorString = "No webcam avaliable";
    }
    else {
      image(t.getTrackerImage(), 0, 0); // display the image from the tracker
      if (drawBlobs) t.showBlobs(/*true*/); // display tracked blobs  
    }
  
    drawInfo(); // on screen text info
   
    if (mousePressed && mouseButton == LEFT) showIgnoreCircle();
    
    t.showIgnoreAreas();
    
    errorString = "";
  
  }
  
  // update email alert prosponer
  kinectAlertProsponer.update();
  
}

float distSq(float x1, float y1, float x2, float y2) {
  float d = (x2-x1)*(x2-x1) + (y2-y1)*(y2-y1);
  return d;
}


float distSq(float x1, float y1, float z1, float x2, float y2, float z2) {
  float d = (x2-x1)*(x2-x1) + (y2-y1)*(y2-y1) +(z2-z1)*(z2-z1);
  return d;
}

void movieEvent(Movie m) {
  m.read();
}

void sendBlobsOsc(){
  
  OscMessage myMessage = new OscMessage("/Blobs|X|Y|MIN_DEPTH|ID|NR_OF_PIXELS|");
  Blob[] blobs = t.getBlobs();
  boolean blobsAdded = false;
  for (Blob b : blobs){
    //println(b.getCenter().x, b.getCenter().y, b.id);
    myMessage.add(int(b.getCenter().x)); // add position x ,y
    myMessage.add(int(b.getCenter().y));
    myMessage.add(int(b.getMinDepth())); // add depth at nearest pixel
    myMessage.add(b.id); // add blob ID
    myMessage.add(int(b.getNrOfPixels())); // add blob nr of pixels
    blobsAdded = true;
  }  
  if (blobsAdded) {
    oscP5_primary.send(myMessage, myRemoteLocation_primary); // send the message if any blobs where added to the OSC message
    if (oscInfo_secondary.length == 4) oscP5_secondary.send(myMessage, myRemoteLocation_secondary); // send the same message to a second receiver
  }
}

void log(String log, String file){
  String [] previousLogs = loadStrings(file);
  String [] logText = {""+day()+"/"+month()+"/"+year()+":"+hour()+":"+minute()+":"+second() +" : "+log};
  if (previousLogs != null) saveStrings(file, append(previousLogs, logText[0]));
  else saveStrings(file, logText);
}
