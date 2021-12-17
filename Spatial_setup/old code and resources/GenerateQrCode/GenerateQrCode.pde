// Renders a QR Code and saves it as a jpeg

import boofcv.processing.*;

String code = "80"; // the string you wish to embed it with

void draw() {

  PImage output = Boof.renderQR(code, 100);

  // Let's see what it looks like
  surface.setSize(output.width, output.height);
  image(output, 0, 0);

  if (frameCount == 10) {
    save(code+".jpeg");
    exit();
  }
}
