// ///////////////////////////////////////////////
//
// p2ma (Pi To Master Arduino) | The Living | 2015
//
// ///////////////////////////////////////////////

// //////// Global variables. ////////

Surface surface;
BubbleRenderer br;

// //////// Global constants. ////////

int RENDER_WIDTH = 50;
int RENDER_HEIGHT = 50;
int SURFACE_WIDTH = 50;
int SURFACE_HEIGHT = 50;
int INPUT_IMAGE_VIEWPORT_WIDTH = 400;
int INPUT_IMAGE_VIEWPORT_HEIGHT = 400;
int STATIC_VIEWPORT_WIDTH = 400;
int STATIC_VIEWPORT_HEIGHT = 400;
int DYNAMICS_VIEWPORT_WIDTH = 400;
int DYNAMICS_VIEWPORT_HEIGHT = 400;
int WINDOW_WIDTH = 1200;
int WINDOW_HEIGHT = 500;
int CELL_SIZE = 8;
int ELEM_SIZE = 6;

void setup() {

    surface = new Surface(SURFACE_WIDTH, SURFACE_HEIGHT);
    br = new BubbleRenderer(RENDER_WIDTH, RENDER_HEIGHT, #000001, false);
}

void settings() {

    size(WINDOW_WIDTH, WINDOW_HEIGHT);
}

void draw() {

    // //// Input image. ////

    PImage inputImage = surface.render();
    surface.update();
    image(inputImage, 0, 0, INPUT_IMAGE_VIEWPORT_WIDTH, INPUT_IMAGE_VIEWPORT_HEIGHT);

    // //// Static bubble render, without physics. ////

    PImage imageBubbles = br.render(inputImage, "rect", CELL_SIZE, ELEM_SIZE);
    image(
        imageBubbles,
        INPUT_IMAGE_VIEWPORT_WIDTH, 0,
        imageBubbles.width, imageBubbles.height);

    // //// Bubble render with simple physics. ////

    // TODO
}

void mouseClicked() {

    // Click on the input image to generate ripples.
    if ((mouseX >= INPUT_IMAGE_VIEWPORT_WIDTH) ||
        (mouseY >= INPUT_IMAGE_VIEWPORT_HEIGHT)) {
        return;
    }

    if (mouseButton == LEFT) {

        // Create a ripple at where the mouse clicked.

        int x = (int) (mouseX * (float) SURFACE_WIDTH / STATIC_VIEWPORT_WIDTH);
        int y = (int) (mouseY * (float) SURFACE_HEIGHT / STATIC_VIEWPORT_HEIGHT);

        Ripple ripple = new Ripple(new PVector(x, y));
        surface.addRipple(ripple);
    }
}
