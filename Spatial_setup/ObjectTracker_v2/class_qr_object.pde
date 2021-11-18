class QRObject{
  
  float x;
  float y;
  int id;
  
  int lastAngle;
  int angle;
  int angleMove;
  int midiAngle;
  
  int rotationVal;
  int midiRotationVal;
  
  PVector lastVector;
  PVector currentVector;
  
  //int rotation;
  int trackingCenterRotation;
  int trackingCenterDistance;
  
  //float rotation_min = 0;
  //float rotation_max = 170;
  //float rotationStep = 1;

  QRObject(int id_){
    id = id_;
    
    lastAngle = -1;
    println("Object added: ", id);
    
  }
  
  void setSelfRotation(int angle_){
    angle = angle_;
    
    if (lastAngle == -1) lastAngle = angle; // this alignes last and current for first call to the function for this object
    //if (dist(lastAngle, 0, angle, 0) > 10) lastAngle = angle; // skips wrong reading when crossing the middle
    
    
    lastVector = new PVector(0, -100);
    lastVector.rotate(radians(lastAngle));
    currentVector = new PVector(0, -100);
    currentVector.rotate(radians(angle));
  
    angleMove = int(degrees(lastVector.angleBetween(lastVector,currentVector))); // total rotational move
    
    if (angle < lastAngle) rotationVal = constrain(rotationVal + angleMove, 0, 359); // rotation one direction
    else if (angle > lastAngle) rotationVal = constrain(rotationVal - angleMove, 0, 359); // rotation the other direction
    midiRotationVal = int(map(rotationVal, 0, 359, 0, 127)); // map to midi
    
    lastAngle = angle;
    
    

    
  }

}
