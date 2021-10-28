/* 
  This is an example code for the Disharmonizing spheres workshop. A workshop by AIR LAB in collaboration with sound artist Louise Foo

  https://airlab.itu.dk / air@itu.dk
  https://fooskou.squarespace.com/

  code by Halfdan Hauch Jensen (halj@itu.dk)
*/

import oscP5.*;               // library for OSC communication
import themidibus.*;          // library for Midi communication

MidiBus myBus; // MIDI object for sending MIDI to Ableton Live

OscP5 oscP5; // OSC object for receiving Kinect blobdata

Blob [] blobsFromKinect; // list of all incoming blobs over OSC - for securely transporting the data to the Blobs array on next line
Blob [] blobs; // list of all blobs - without 

String mode = "simulate"; // set to "simulate" for mouse simulation, or "kinect" for tracking data from kinect 

// Coordinate of lamp in the tracking area
int lampX = 320;
int lampY = 240;

// Data translation
float distToLampCenter = 0;
float mappedDistMidi = 0;
float constrainedDistMidi = 0;


void setup() {
  size(640, 480);
  frameRate(25);
  
  MidiBus.list(); // List all available Midi devices on STDOUT. This will show each device's index and name.
  
  myBus = new MidiBus(this, -1, "My Live Session"); // Create a new MidiBus with no input device and "Bus 1" as the output device.
  
  oscP5 = new OscP5(this, 6789); // listening for incoming OSC messages at port 6789
  
}


void draw() {
  // ------------------------------- leave this code here -------------------------------------------
  if (mode == "simulate"){
    blobs = new Blob[1];
    blobs[0] = new Blob(mouseX, mouseY, 10000, 1, 500);
  }
  
  else if (mode == "kinect") {    
    blobs = getBlobs(blobsFromKinect);
    
    if (blobs == null) {
      return; // if the mode is "kinect" but the kinect data is not ready, stop this iteration of draw
    }
  }
  // -------------------------------------------------------------------------------------------------
  
  
  
  
  // -------------------------- write your draw code below this line ---------------------------------
  
  // translate person coordinates to Midi values
  distToLampCenter = dist(blobs[0].x, blobs[0].y, lampX, lampY);   // calculate distance from the person(blob) to the lamp
  mappedDistMidi = map(distToLampCenter, 0, 200, 127, 0);          // map the value to a fitting scale for Midi
  constrainedDistMidi = constrain(mappedDistMidi, 0, 127);         // constrain the value to keep within the Midi scale (0 - 127)
    
    
  // display visualize elements
  background(0);
  noStroke();
  fill(255); // set fill color to white
  text("Mode: " + mode, 5, 15);
  fill(0,0,255); // set fill color to blue
  ellipse(blobs[0].x, blobs[0].y, 10, 10); // draw person/blob
  ellipse(lampX, lampY, 100, 100); // draw the lamp
  
  exampleVisualizer(); // function for visually explaining number mappings and constrains
    
  // Send Midi data to Ableton Live
  myBus.sendControllerChange(0, 1, int(constrainedDistMidi)); // send midi data parameter order (channel, number, value)
  
  // ----------------------------------------------------------------------------------------------------
}


// function for key controls
void keyReleased(){
  
  // keys for toggeling between modes
  if (key == 's') mode = "simulate";
  else if (key == 'k') mode = "kinect";

}
