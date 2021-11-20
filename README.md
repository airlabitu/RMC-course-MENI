# RMC-course-MENI
## Repository for the RMC course Musical expressions for new interfaces (fall 2021)

### AIR LAB Kinect setup - day 1 - 29th of October

#### Preperations
Download Processing version 3.5.4 [link](https://github.com/processing/processing/releases/download/processing-0270-3.5.4/processing-3.5.4-macosx.zip)<br >
Move processing to your **Applications** folder<br >
Download this repository, and move it somewhere you can find it :-)<br >
Open Processing and install the following libraries from the menu: **Sketch -> import library -> add library**<br >
- Sound (by: The Processing Foundation)
- oscP5 (by: Andreas Schlegel)
- The MidiBus (by: Severin Smith)
- Open Kinect for Processing (by: Daniel Shiffman and Thomas Sanchez)
- Video (by: The Processing Foundation)

#### Tech setup guide
- Place the objects (if not already done)
- Setup **Bus 1** in MIDI studio (from: **Audio MIDI Setup -> window -> Show MIDI studio**)
- Setup MIDI input in Ableton
- Open and run: **KinectBlobTracker** from this repository
- Open and run: **Sound_control** from this repository
    - add circles over objects in Sound_control

[setup instruction video part 1](https://youtu.be/SQx9Hn1EwzM)<br >
[setup instruction video part 2](https://youtu.be/urzS0Gm8BKo)


### AIR LAB Quadrophonic setup day 1 - 19th of November

The object fiducials (code tags) holds the ID numbers 10, 20, 30, 40, 50, 60, 70, 80 etc. 

For the MIDI mapping this means the following:

Object ID (10) sends the following control change messages:<br >
- CC message (channel = 0, number = 10, value = 0-127) (objects rotation around tracking area center) - maps to AZIM<br >
- CC message (channel = 0, number = 11, value = 0-127) (objects distance to tracking area center) - maps to RADIUS<br >
- CC message (channel = 0, number = 12, value = 0-127) (objects own rotation)<br >
- CC message (channel = 0, number = 13, value = 0 or 127) (127 when object enters tracking area, 0 when it leaves again)<br >
- CC message (channel = 0, number = 14, value = 0-127) (same triggers as 13 but fades between the two boundry values)<br >

Object ID (20) sends the following control change messages:<br >
- CC message (channel = 0, number = 20, value = 0-127) (objects rotation around tracking area center) used for spatialization AZIM<br >
- ... and it continues like this, with increments of 10 between first CC message number for each object<br >

