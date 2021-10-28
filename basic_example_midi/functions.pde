// ----------- HELPER FUNCTIONS - leave as is, unless you know what you are changing works ;-) ---------------


// function for getting blobs, and catching potential data errors  
Blob[] getBlobs(Blob [] inputArray){
  Blob [] returnArray;
    try{
      returnArray = new Blob[inputArray.length];
      for (int i = 0; i < inputArray.length; i++){
        
        returnArray[i] = new Blob(inputArray[i].x, inputArray[i].y, inputArray[i].minDepth, inputArray[i].id, (int)inputArray[i].nrOfPixels);
      }
    } 
    catch (NullPointerException e){
      //println("catched ERROR and returns NULL");
      return null;
    }
    return returnArray;
}



// function helping visualize the translation of values - for instruction purpose
void exampleVisualizer(){
  fill(255);
  text("distToCenter : " + int(distToLampCenter), 5, 40);
  text("mappedDistMidi : " + int(mappedDistMidi), 5, 60);
  text("constrainedDistMidi : " + int(constrainedDistMidi), 5, 80);
  noFill();
  stroke(255);
  line(lampX, lampY, blobs[0].x, blobs[0].y); // distToLampCenter
  ellipse(lampX, lampY, mappedDistMidi, mappedDistMidi); // mappedDistMidi
  ellipse(lampX, lampY, 200*2, 200*2); // interaction space
  ellipse(lampX, lampY, constrainedDistMidi+5, constrainedDistMidi+5); // constrainedDistMidi

}
