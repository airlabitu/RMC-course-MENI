class DepthPixel{
  float x, y, depth;
  
  DepthPixel(float x_, float y_, float depth_){
    x = x_;
    y = y_;
    depth = depth_;
  }
  
  DepthPixel getCopy(){
    return new DepthPixel(x, y, depth);
  }
}
