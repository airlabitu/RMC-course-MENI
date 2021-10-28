/* 
  This is code for a midi mapping appication to use with Ableton Live, or other midi enabled sound software, together with Processing
  code by AIR LAB made by Halfdan Hauch Jensen (halj@itu.dk)
  https://airlab.itu.dk / air@itu.dk
  
*/

import themidibus.*; // library for Midi communication

MidiBus myBus; // MIDI object for sending MIDI to Ableton Live


int midiButtons[][] = 
{
  {1,2,3,4,5,6,7,8,9,10},
  {11,12,13,14,15,16,17,18,19,20},
  {21,22,23,24,25,26,27,28,29,30}
};

String messageSend;

void setup() {
  size(510, 200);
  frameRate(25);
  
  MidiBus.list(); // List all available Midi devices on STDOUT. This will show each device's index and name.
  
  myBus = new MidiBus(this, -1, "Bus 1"); // Create a new MidiBus with no input device and "Bus 1" as the output device.
  

}


void draw() {
  background(0);
  for (int x = 0; x < midiButtons[0].length; x++){
    for (int y = 0; y < midiButtons.length; y++){
      rect(x*40+10+x*10, y*40+10+y*10, 40, 40);
      fill(0);
      text(""+midiButtons[y][x], x*40+10+x*10+15, y*40+10+y*10+25);
      fill(255);
    }
  }
  if (messageSend != null) text(messageSend, 10, 180);
}

void mouseReleased(){
  for (int x = 0; x < midiButtons[0].length; x++){
    for (int y = 0; y < midiButtons.length; y++){
      if (mouseX > x*40+10+x*10 && mouseX < x*40+10+x*10+40 && mouseY > y*40+10+y*10 && mouseY < y*40+10+y*10+40){
        println(midiButtons[y][x]); // send midi data parameter order (channel, number, value)  )
        myBus.sendControllerChange(0, midiButtons[y][x], 0); // send midi data parameter order (channel, number, value)
        messageSend = "Last message: channel(0) number("+midiButtons[y][x]+") value(0) - sent at: " + hour()+":"+minute()+":"+second();
      }
    }
  }
}
