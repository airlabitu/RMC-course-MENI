class QRObject{
  
  int id;
  float lastAngle;
  float currentAngle;
  float rotation;
  float rotation_min = 0;
  float rotation_max = 170;
  float rotationStep = 1;

  QRObject(int id_){
    id = id_;
    println("Object added: ", id);
    
  }
  
  void update(float angle_){
     currentAngle = angle_;
    
    
    }

}
