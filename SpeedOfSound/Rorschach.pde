class Rorschach {
  int nBalls = 99;
  int nSteps;
  float vMax;
  //i, x,y,vx,vy
  float[][] balls;
  int sliderValue = 50;
  int ballShapeMode;
  int numBallShapes = 3;
  int movementMode;
  boolean invertAlpha = false;
  boolean blackBackground;
  color backgroundColor;
  color ballColor;
  boolean randomColor;
  PImage ballImage;
  int radius;
  boolean overlay = true;
  
  int speedUp = 2;
  
  boolean generatingImage = false;
  
  // These should be in the rorshcach layer class...
  boolean applyThreshold = true;
  float thresh = 0.1;
  boolean active = false;

  GLGraphicsOffScreen rOffscreen;  // Used to store the Rorschach so we can apply pixel filters
  GLTexture texDest; // Used as a destination for pixel-filtered offscreen graphics.
  GLTextureFilter threshhold; // This links to the Threshhold filter used by Rorschach

  Rorschach(PApplet parent) {
    init();
    rOffscreen = new GLGraphicsOffScreen(parent, width, height); // Init the offscreen buffer
    texDest = new GLTexture(parent, width, height); // Texture
    threshhold = new GLTextureFilter(parent, "threshold.xml"); // And threshhold
  }
  
  void init() {
    resetParams();
    generateImage();
    generateBalls();
    
  }
  
    void handleOSC(OscMessage o) {
    String path = o.addrPattern();
    String elements[] = path.split("/");
    if (elements[2].equals("Active")) {
      int bool = int(round(o.get(0).floatValue()));
      if (bool == 1) {
        active = true;
        //pArtist.active = false;
      } else {
        active = false;
        //pArtist.active = true;
      }
    } else if (elements[2].equals("Threshold") && 
      elements[3].equals("On")) {
      int bool = int(round(o.get(0).floatValue()));
      if (bool == 1) {
        applyThreshold = true;
      } else {
        applyThreshold = false;
      }
    } else if (elements[2].equals("Invert")) {
      int bool = int(round(o.get(0).floatValue()));
      if (bool == 1) {
        invertAlpha = true;
      } else {
        invertAlpha = false;
      }
    } else if (elements[2].equals("Overlay")) {
      int bool = int(round(o.get(0).floatValue()));
      if (bool == 1) {
        overlay = true;
      } else {
        overlay = false;
      }
      // Send Active back to Lemur to update multiple button
      oscSendOverlay(osc.oscP5, osc.oscDestination);
    } else if (elements[2].equals("Reset")) {
      resetParams();
      while(true) {
        if (!generatingImage) {
          generateImage();
          break;
        }
      }
      osc.setAll();
    } else if (elements[2].equals("NumBalls")) {
      nBalls =  int(round(o.get(0).floatValue()));;
    } else if (elements[2].equals("BlobMoveMode")) {
      int modeCount = o.typetag().length();
      int mIndex = 0;
      for (int i = 0; i < modeCount; i++) {
        float x = o.get(i).floatValue();
        if (x == 1.0) {
          mIndex = i; break;
        }
      }
      movementMode = mIndex;
    } else if (elements[2].equals("BlobSize")) {
      while(true) {
        if (!generatingImage) {
          radius = int(round(o.get(0).floatValue()));
          generateImage();
          break;
        }
      }
    }
    else if (elements[2].equals("BeatIncrement")) {
      speedUp = int(round(o.get(0).floatValue()));
    }
  }
  
  void paint(){
    
    moveBalls();
    if(beat.isKick()) {
      for(int i = 0; i < speedUp; i++) {
        moveBalls();
      }
    }

    rOffscreen.beginDraw(); // Begin drawing offscreen
    if (overlay) {
        rOffscreen.setBlendMode(GLGraphicsOffScreen.ADD); // Begin drawing offscreen
    }    
    rOffscreen.background(0);
    for(int i=0; i<nBalls; i++){
        // Render mirror-images of the balls
        rOffscreen.image(ballImage,(width-balls[i][0])-radius,balls[i][1]-radius);
        rOffscreen.image(ballImage,balls[i][0]-radius,balls[i][1]-radius);
    }
    if (invertAlpha) {
      // TODO, write GLSL script for invert
      //rOffscreen.getTexture().filter(INVERT, texDest);
      rOffscreen.image(texDest, 0, 0);
    }  
    rOffscreen.endDraw();
    if (applyThreshold) { // Apply or not apply Threshhold filter
      rOffscreen.getTexture().filter(threshhold, texDest);
      image(texDest, 0, 0);
    } else {
      image(rOffscreen.getTexture(), 0, 0);
    }
  }
  
  void resetParams(){
    movementMode = 0;
    ballShapeMode = 0;
    applyThreshold = true;
    invertAlpha = false;
    blackBackground = false;
    randomColor = false;

    nBalls = 99;
    nSteps = 6;
    thresh = .1;
    vMax = 3;
    balls = new float[nBalls][4];
    backgroundColor = color(0);
    ballColor = color(255);
    radius = 50;
  }
  
  void generateBalls(){
    for(int i=0; i<nBalls; i++)
      generateBall(i);
  }

  void generateBall(int i){
    balls[i][0] = random(radius,width-radius);
    balls[i][1] = random(radius,height-radius);
    balls[i][2] = random(-vMax,vMax);
    balls[i][3] = random(-vMax,vMax);
  }
  
  void moveBalls(){
    //a fountain! -- key 0
    if(movementMode ==0){
      float v = -(height+radius)/26;
      float theta = 0;
      for(int i=0; i<nBalls; i++){
        if(balls[i][0] < -2*radius || balls[i][0] > width+radius ||
           balls[i][1] > height+radius){
          v += random(-2,10);
          theta = random(-.2,.2);
          balls[i][0] = width/2;
          balls[i][1] = height-radius;
          balls[i][2] = v*sin(theta);
          balls[i][3] = v*cos(theta);
        }

        balls[i][3]-= v/30;
        balls[i][0] +=balls[i][2];
        balls[i][1] +=balls[i][3];
      }
    }

    //swirling around
    if(movementMode ==1){
      for(int i=0; i<nBalls; i++){
        if(balls[i][0] >=radius && balls[i][0] <= width-radius &&
           balls[i][1] >=radius && balls[i][1] <= height-radius){
          balls[i][2]+= (width/2-balls[i][0])/(width/2)*random(.9,4.4);
          balls[i][3]+= (height/2-balls[i][1])/(height/2)*random(.9,2.4);
          balls[i][0]+= balls[i][2];
          balls[i][1]+= balls[i][3];
        }
        else{
          balls[i][0] = random(radius,width-radius);
          balls[i][1] = random(radius,height-radius);
          balls[i][2] = 0;
          balls[i][3] = 0;
        }

        balls[i][0] +=balls[i][2];
        balls[i][1] +=balls[i][3];
      }
    }

    //orbits!
    if(movementMode ==2){
      float rSquared = 0;
      float theta = 0;
      float vel0 = max(width,height)/150;
      float vel = vel0+0;
      for(int i=0; i<nBalls; i++){
        rSquared = (balls[i][0]-width/2)*(balls[i][0]-width/2)+
                   (balls[i][1]-height/2)*(balls[i][1]-height/2);
        theta = atan2(balls[i][1]-height/2,balls[i][0]-width/2);

        if(rSquared > max(width+radius,height+radius)*max(width+radius,height+radius)*.25){
            balls[i][0] = random(radius,width-radius);
            balls[i][1] = random(radius,height-radius);
            balls[i][2] = 0;
            balls[i][3] = 0;
           }
        vel = vel0*(1-rSquared/(width*width/(40)));
        balls[i][0]+= vel*cos(theta+PI/2);
        balls[i][1]+= vel*sin(theta+PI/2);
      }
    }

    //swirl in!
    if(movementMode == 3){
      float rSquared = 0;
      float theta = 0;
      float vel0 = max(width,height)/150;
      float vel = vel0+0;
      float rSquaredMax = (width/2+radius)*(width/2+radius);
      for(int i=0; i<nBalls; i++){
        rSquared = (balls[i][0]-width/2)*(balls[i][0]-width/2)+
                   (balls[i][1]-height/2)*(balls[i][1]-height/2);
        theta = atan2(balls[i][1]-height/2,balls[i][0]-width/2);

        if(rSquared > rSquaredMax || rSquared < 200.0){
          rSquared = (width/2+radius/2)*(width/2+radius/2);//rSquaredMax*.9;
          theta = random(TWO_PI);
          balls[i][0] = width/2+sqrt(rSquared)*cos(theta);
          balls[i][1] = height/2+sqrt(rSquared)*sin(theta);
          balls[i][2] = 0;
          balls[i][3] = 0;
         }

        balls[i][0]-= (4*cos(theta+PI/2)+cos(theta)*(1+rSquared/rSquaredMax));
        balls[i][1]-= (4*sin(theta+PI/2)+sin(theta)*(1+rSquared/rSquaredMax));
      }
    }

    //They're all repulsive!
    if(movementMode == 4){
      float rSquared = 0;
      float force = 0;
      float theta = 0;
      for(int i=0; i<nBalls; i++){
        for(int j=0; j<nBalls; j++)
          if(i!=j){
            rSquared = (balls[i][0]-balls[j][0])*(balls[i][0]-balls[j][0])+
                       (balls[i][1]-balls[j][1])*(balls[i][1]-balls[j][1]);
            theta = atan2(balls[j][1]-balls[i][1],balls[j][0]-balls[i][0]);

            balls[i][2]+= -1/rSquared*cos(theta)*2E2;
            balls[i][3]+= -1/rSquared*sin(theta)*2E2;
        }
        balls[i][2] += (1/balls[i][0]+1/((balls[i][0]-width )))*nBalls/10;
        balls[i][3] += (1/balls[i][1]+1/((balls[i][1]-height)))*nBalls/10;

        balls[i][2] = balls[i][2]*.95;
        balls[i][3] = balls[i][3]*.95;

        balls[i][0] += balls[i][2];
        balls[i][1] += balls[i][3];
      }
    }

    //They're repulsive, attractive!
    if(movementMode == 5){
      float rSquared = 0;
      float force = 0;
      float theta = 0;
      for(int i=0; i<nBalls; i++){
        for(int j=0; j<nBalls; j++)
          if(i!=j){
            rSquared = (balls[i][0]-balls[j][0])*(balls[i][0]-balls[j][0])+
                       (balls[i][1]-balls[j][1])*(balls[i][1]-balls[j][1]);
            theta = atan2(balls[j][1]-balls[i][1],balls[j][0]-balls[i][0]);

            balls[i][2]+= -(3*radius/rSquared-1/sqrt(rSquared))*cos(theta)*20.0/nBalls;
            balls[i][3]+= -(3*radius/rSquared-1/sqrt(rSquared))*sin(theta)*20.0/nBalls;
        }
        balls[i][2] += (1/balls[i][0]+1/((balls[i][0]-width )))*nBalls/10;
        balls[i][3] += (1/balls[i][1]+1/((balls[i][1]-height)))*nBalls/10;

        balls[i][2] = balls[i][2]*.99;
        balls[i][3] = balls[i][3]*.99;

        balls[i][0] += balls[i][2];
        balls[i][1] += balls[i][3];
      }
    }

     //swirling around
    if(movementMode ==6){
      for(int i=0; i<nBalls; i++){
        if(balls[i][0] >=radius && balls[i][0] <= width-radius &&
           balls[i][1] >=radius && balls[i][1] <= height-radius){
          balls[i][2]+= (width/2-balls[i][0])/(width/2)*random(.9,9.1);
          balls[i][3]+= (height/2-balls[i][1])/(height/2)*random(.9,9.1);
          balls[i][0]+= balls[i][2];
          balls[i][1]+= balls[i][3];
        }
        else{
          balls[i][0] = random(radius,width-radius);
          balls[i][1] = random(radius,height-radius);
          balls[i][2] = 0;
          balls[i][3] = 0;
        }

        balls[i][0] +=balls[i][2];
        balls[i][1] +=balls[i][3];
      }
    }
     //swirling around
    if(movementMode ==7){
      for(int i=0; i<nBalls; i++){
        if(balls[i][0] >=radius && balls[i][0] <= width-radius &&
           balls[i][1] >=radius && balls[i][1] <= height-radius){
          balls[i][2]+= (width/2-balls[i][0])/(width/2)*random(.9,4.4);
          balls[i][3]+= (height/2-balls[i][1])/(height/2)*random(.9,.6);
          balls[i][0]+= balls[i][2];
          balls[i][1]+= balls[i][3];
        }
        else{
          balls[i][0] = random(radius,width-radius);
          balls[i][1] = random(radius,height-radius);
          balls[i][2] = 0;
          balls[i][3] = 0;
        }

        balls[i][0] +=balls[i][2];
        balls[i][1] +=balls[i][3];
      }
    }


  }
  
  void generateImage(){
    generatingImage = true;
    if(ballShapeMode == 0)
      generateCircleImage();
    generatingImage = false;
  }


  void generateCircleImage(){
    ballImage = createImage(radius*2,radius*2,ARGB);
    color thisColor = color(0,0,0,0);
    float rSquared = 0;
    for(int x= 0; x<=radius; x++) {
      for(int y= 0; y<=radius; y++){
        rSquared = pow(x-radius,2)+pow(y-radius,2);
        if(rSquared<radius*radius){
          if(invertAlpha)
            thisColor = color(255*(rSquared/(radius*radius)));
          else
            thisColor = color(255*(1-rSquared/(radius*radius)));
          ballImage.set(x,y,thisColor);
          ballImage.set(2*radius-x,y,thisColor);
          ballImage.set(2*radius-x,2*radius-y,thisColor);
          ballImage.set(x,2*radius-y,thisColor);
        }
        else {
          ballImage.set(x,y,color(0,0,0,0));
        }
      }
    }
  }

  void oscSendState(OscP5 osc, NetAddress oscDestination) {
    oscSendNumBalls(osc,oscDestination);
    oscSendActive(osc,oscDestination);
    oscSendThresholdOn(osc,oscDestination);
    oscSendRadius(osc,oscDestination);
    oscSendBeatIncrement(osc,oscDestination);
    oscSendMode(osc,oscDestination);
    oscSendInvert(osc,oscDestination);
    oscSendOverlay(osc,oscDestination);
  }

  void oscSendNumBalls(OscP5 osc, NetAddress oscDestination) { // Set all the Lemur controls to current values.      
    OscMessage ballsOsc = new OscMessage("/Rorschach/NumBalls");
    float num = nBalls;
    ballsOsc.add(num);
    
    osc.send(ballsOsc, oscDestination);      
  }
    
  void oscSendActive(OscP5 osc, NetAddress oscDestination) { // Set all the Lemur controls to current values.      
    OscMessage toggleOsc = new OscMessage("/Rorschach/Active");
    if (active) {
      toggleOsc.add(1.0);
    } else {
      toggleOsc.add(0.0);
    }
    osc.send(toggleOsc, oscDestination);      
  }

  void oscSendInvert(OscP5 osc, NetAddress oscDestination) { // Set all the Lemur controls to current values.      
    OscMessage toggleOsc = new OscMessage("/Rorschach/Invert");
    if (invertAlpha) {
      toggleOsc.add(1.0);
    } else {
      toggleOsc.add(0.0);
    }
    osc.send(toggleOsc, oscDestination);      
  }
  
  void oscSendOverlay(OscP5 osc, NetAddress oscDestination) { // Set all the Lemur controls to current values.      
    OscMessage toggleOsc = new OscMessage("/Rorschach/Overlay/On");
    if (overlay) {
      toggleOsc.add(1.0);
    } else {
      toggleOsc.add(0.0);
    }
    osc.send(toggleOsc, oscDestination);      
  }
  
  void oscSendThresholdOn(OscP5 osc, NetAddress oscDestination) { // Set all the Lemur controls to current values.      
    OscMessage toggleOsc = new OscMessage("/Rorschach/Threshold/On");
    if (applyThreshold) {
      toggleOsc.add(1.0);
    } else {
      toggleOsc.add(0.0);
    }
    osc.send(toggleOsc, oscDestination);      
  }
  
  void oscSendRadius(OscP5 osc, NetAddress oscDestination) {
    OscMessage radiusOsc = new OscMessage("/Rorschach/BlobSize");
    float rad = radius;
    radiusOsc.add(rad);
    osc.send(radiusOsc, oscDestination);
    //while(true) {
    //  if (!generatingImage) {
    //    generateImage();
    //    break;
    //}
    //}
  }
  
  void oscSendBeatIncrement(OscP5 osc, NetAddress oscDestination) {
    OscMessage msg = new OscMessage("/Rorschach/BeatIncrement");
    msg.add(float(speedUp));
    osc.send(msg, oscDestination);
  }
  
  void oscSendMode(OscP5 osc, NetAddress oscDestination) {
    OscMessage radiusOsc = new OscMessage("/Rorschach/BlobMoveMode");
    float[] vec = new float[8];
    for (int i = 0; i < 8; i++) {
      if (i == movementMode) {
        vec[i] = 1.0;
      } else {
        vec[i] = 0.0;
      }
    }
    radiusOsc.add(vec);
    osc.send(radiusOsc, oscDestination);
  }


}
