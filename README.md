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

QR koderne er lavet således at de hver indeholder et af tallene, 1, 10, 20, 30... og bliver softwaren indrettet til at sende CC beskeder ud på numre der følger systemet herunder...

(QR 1) 1,2,3
(QR 10) 10,11,12
(QR 20) 20,21,22
etc.


Her lige to eksempler på objekter->beskeder:


De sender som sagt alle 3 CC MIDI beskeder. 


For QR koden 1 ser det således ud.

CC besked (channel = 0, number = 1, value = "rotation om kamera center")
CC besked (channel = 0, number = 2, value = "radius/afstand til kamera center")
CC besked (channel = 0, number = 3, value = "rotation om objektets eget center")

For QR koden 10 ser det således ud.

CC besked (channel = 0, number = 10, value = "rotation om kamera center")
CC besked (channel = 0, number = 11, value = "radius/afstand til kamera center")
CC besked (channel = 0, number = 12, value = "rotation om objektets eget center")