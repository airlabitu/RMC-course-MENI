// This is the sound sketch for the RMC course Musical expressions for new interfaces at AIR LAB ITU
// Code by AIR LAB - Halfdan Hauch Jense - halj@itu.dk

import oscP5.*;
import processing.sound.*;
import themidibus.*;          // library for Midi communication

MidiBus myBus; // MIDI object for sending MIDI to Ableton Live

OscP5 oscP5;
Blob [] blobs;
int framesSinceLastOscMessage = 0;

//Sphere [] spheres;
ArrayList<Sphere> spheres = new ArrayList<Sphere>();

boolean mode = false;

int millisToFadeInside = 300;
int millisToFadeOutside = 1000;
int millisToFadeNoBlobs = 5000;

boolean groupsEnabled = false;

boolean placingSpheres = false;


void setup() {
  size(640, 480);
  frameRate(25);
  //textAlign(CENTER);
  textSize(15);
  oscP5 = new OscP5(this, 6789);

  loadSpheres(); // loads spheres from sphere-settings.txt file in data folder
  
  myBus = new MidiBus(this, -1, "Bus 1"); // Create a new MidiBus with no input device and "Bus 1" as the output device.

}


void draw() {
  background(0);

  for (Sphere s : spheres) {
    s.show(255, 255, 255);
    s.update();
    if (mode) mouseInteraction(s, spheres, "LINEAR_FADE");
    else blobsInteraction(s, spheres, "LINEAR_FADE");
    myBus.sendControllerChange(0, s.id, constrain(int(map(s.vol.val, s.vol.getMin(), s.vol.getMax(), 0, 127)), 0, 127)); // send midi data parameter order (channel, number, value)

  }
  
  // UI info
  fill(255);
  if (mode) text("Mode (m) : MOUSE", 5, 20);
  else text("Mode (m) : KINECT", 5, 20);
  if (placingSpheres) text("Placing spheres (p) : ON", 5, 40);
  else text("Placing spheres (p) : OFF", 5, 40);
       text("Next ID : " + nextID, 5, 60);
  
  if (mousePressed && mouseButton == LEFT) showSphereCircle(); // shows circle while placing a sphere
  
}
