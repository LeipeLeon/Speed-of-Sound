class BackgroundArtist {
    color c;
    BackgroundArtist() {
	c = #000000;
    }

    void init(Object o) {
	c = ((Integer) o).intValue();
    }

    boolean doesClear() {
	// whether or not the background explicitly clears things first
	return true;
    }

    void paint() {
	// draws background
	background(c);
    }
}


class MovieBackgroundArtist extends BackgroundArtist {
    PImage[] frames;
    int currentFrame;
    int maxFrames = 25; // 25 fps * 5 seconds
    int totalFrames; // less than max if not enough in movie.
    Movie m;

    MovieBackgroundArtist() {
	currentFrame = 0;
	totalFrames = 0;
	frames = new PImage[maxFrames];
    }

    void init(Object o) {
	m = (Movie) o;
	//Movie m = (Movie) o;
	// Read a series of frames into a image array (running video real time
	// is sloooow.
	int counter = 0;
	while (counter < maxFrames) { // && m.time() <= m.duration()) {
	    if (m.available()) {
		m.read();
		frames[counter] = m.get();
		counter++;
	    }
	}
        totalFrames=counter;
    }

    void paint() {
        if (m.available()) {
            m.read();
        }
	image(m,0,0,width,height);
	//if (totalFrames < 1) return;
	//image(frames[currentFrame],0,0,width,height);
	//currentFrame++;
	//if (currentFrame >= totalFrames) currentFrame = 0;
    }

}

// Normally the below would go in a separate Factory class, but Processing makes
// everythin an inner class, which prevents us having static methods.
String[] backgroundArtistTypes = {
    "BlankBackgroundArtist",
    "ImageBackgroundArtist",
    "MovieBackgroundArtist"
};


BackgroundArtist createBackgroundArtist(String t) {
    if (t.equals("BlankBackgroundArtist")) {
	return new BackgroundArtist();
    //case ImageBgArtist:
//      return new ImageBgArtist();
    } else if (t.equals("MovieBackgroundArtist")) {
        return new MovieBackgroundArtist();
    } else {
	println("Unknown or unimplemented artist type");
	return null;
    }
   
}