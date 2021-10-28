import netP5.*;

class OscAlertProsponer{
  boolean isActive;
  long timer;
  int interval;
  String addressPattern;

  OscP5 osc;
  NetAddress emailNotifyerLocation;
  
  OscAlertProsponer(OscP5 osc_, String ip_, int port_, String addressPattern_){
    emailNotifyerLocation = new NetAddress(ip_, port_);
    interval = 5000; // default updating frequincy
    addressPattern = addressPattern_;
    osc = osc_;
  }
  
  void update(){
    if (millis() > timer + interval){
      timer = millis();
      prosponeAlert(); 
    }
  }
  
  void prosponeAlert(){
    if (isActive){
      OscMessage myMessage = new OscMessage(addressPattern);
      //println("Message:", myMessage.addrPattern());
      osc.send(myMessage, emailNotifyerLocation);
    }
    else println("Alert not active", addressPattern);
  }
  
}
