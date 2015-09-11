// ///////////////////////////////////////////////
//
// p2ma (Pi To Master Arduino) | The Living | 2015
//
// ///////////////////////////////////////////////

// //////// Global variables. ////////

Surface surface;
BubbleRenderer br;
Simulator simulator;

// `True` if the simulation is running.
boolean play = true;

// //////// Global constants. ////////

final int SURFACE_WIDTH = 50;
final int SURFACE_HEIGHT = 50;

final int SIMULATOR_WIDTH = 300;
final int SIMULATOR_HEIGHT = 300;

final int SURFACE_VIEWPORT_WIDTH = 300;
final int SURFACE_VIEWPORT_HEIGHT = 300;

final int RENDERER_VIEWPORT_WIDTH = 300;
final int RENDERER_VIEWPORT_HEIGHT = 300;

final int SIMULATOR_VIEWPORT_WIDTH = 300;
final int SIMULATOR_VIEWPORT_HEIGHT = 300;

final int WINDOW_WIDTH = 900;
final int WINDOW_HEIGHT = 300;

final int CELL_SIZE =
    RENDERER_VIEWPORT_WIDTH /
    (BubbleRenderer.N_NOZZLES_PER_TANK * BubbleRenderer.N_TANK_COLUMNS);
final int ELEM_SIZE = (int)(CELL_SIZE * 0.75);

void setup() {

    surface = new Surface(SURFACE_WIDTH, SURFACE_HEIGHT);
    br = new BubbleRenderer(#000001, false);
    simulator = new Simulator(SIMULATOR_WIDTH, SIMULATOR_HEIGHT);
}

void settings() {

    size(WINDOW_WIDTH, WINDOW_HEIGHT);
}

void draw() {

    // Update the surface and the bubble renderer only when the simulator is
    // not busy.
    if (!simulator.isBusy()) {

        // //// Surface. ////

        PImage imageSurface = surface.render();
        image(imageSurface, 0, 0,
              SURFACE_VIEWPORT_WIDTH, SURFACE_VIEWPORT_HEIGHT);
        surface.update();

        // //// Bubble renderer. ////

        PImage imageRenderer = br.render(imageSurface, "rect", CELL_SIZE, ELEM_SIZE);
        image(imageRenderer, SURFACE_VIEWPORT_WIDTH, 0,
              imageRenderer.width, imageRenderer.height);

        // Send signals to simulator only if there is any ripple on
        // the surface.
        if (surface.getRipples().size() > 0) {
            short[][] signals = br.getSignals(imageSurface);
            simulator.send(signals);
        }
    }

    // //// Simulator. ////

    PImage imageSimulator = simulator.render();
    image(imageSimulator,
          SURFACE_VIEWPORT_WIDTH + RENDERER_VIEWPORT_WIDTH, 0,
          SIMULATOR_VIEWPORT_WIDTH, SIMULATOR_VIEWPORT_HEIGHT);

    // Update the simulator only if the simulation is playing.
    if (play) simulator.update();
}

void mouseClicked() {

    // Click on the surface viewport to generate ripples.
    if ((mouseX >= SURFACE_VIEWPORT_WIDTH) ||
        (mouseY >= SURFACE_VIEWPORT_HEIGHT)) {

        return;
    }

    // Create a ripple at where the mouse clicked.
    if (mouseButton == LEFT) {

        int x = (int) (mouseX * (float) SURFACE_WIDTH / RENDERER_VIEWPORT_WIDTH);
        int y = (int) (mouseY * (float) SURFACE_HEIGHT / RENDERER_VIEWPORT_HEIGHT);

        Ripple ripple = new Ripple(new PVector(x, y));
        surface.addRipple(ripple);
    }
}

void keyPressed() {

    switch (key) {

        // "p" for "pause".
        case 'p':

            // Toggle the `play` flag.
            play = !play;
            break;

        // "s" for "step".
        case 's':

            // We only need to update the simulator, which drives the update
            // of the surface and the bubble renderer.
            simulator.update();
            break;
    }
}
