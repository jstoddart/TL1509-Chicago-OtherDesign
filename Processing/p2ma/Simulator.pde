// ///////////////////////////////////////////////
//
// p2ma (Pi To Master Arduino) | The Living | 2015
//
// ///////////////////////////////////////////////

// A simulator for the design based on the drawings in `BubbleRenderer.pde`.
// This simulator adds dynamics to the design.
// Note that the coordinate system of the simulator, along with all the
// objects in it (e.g. tanks and bubbles) is consisten with that of the
// window GUI, meaning that x axis points to the right and y axis points up.
public class Simulator {

    // //////// Constructors. ////////

    // Initialize a simulator with the design of `sizeX` by `sizeY`.
    public Simulator(float sizeX, float sizeY) {

        this.sizeX = sizeX;
        this.sizeY = sizeY;
        pg = createGraphics((int)sizeX, (int)sizeY);
        tanks = new ArrayList<Tank>();

        // The simulator is initialize as not busy.
        signalsFrame = -1;
        signals = null;

        addTanks();
    }

    // //////// Methods. ////////

    // Send signals to the simulator. The signals will be ignored if
    // the simulator is busy, and `send` returns `false` in this case.
    // Otherwise the signals will be queued and `send` returns `true`.
    public boolean send(short[][] signals) {

        if (isBusy()) return false;

        // Save the signals and reset the signal frame pointer.
        this.signals = signals;
        signalsFrame = 0;
        return true;
    }

    // Check if the simulator is busy, i.e. in the middle of responding to
    // signals.
    public boolean isBusy() {

        // Return true if the simulator still has signals to repond to.
        return signalsFrame >= 0;

        // Alternatively, we can define the status of being busy as there being
        // at least one tank with at least one bubble. This effectively enables
        // simulator to accept command only if all tanks are empty, lowering
        // the refresh rate.

        // for (Tank tank : tanks) {
        //     if (tank.getBubbles().size() > 0)
        //         return true;
        // }
        // return false;
    }

    // Update the simulator, which involves consuming signals by one frame and
    // updating the dynamics.
    public void update() {

        // //// Handle the signals. ////

        // If there are signals to be run.
        if ((signals != null) && (signalsFrame < signals.length)) {

            // Distribute the signals to individual tanks.
            for (int i = 0; i < signals[signalsFrame].length; ++i) {
                tanks.get(i).send(signals[signalsFrame][i]);
            }

            // Increment the signal frame to point to the signals for the
            // next frame.
            ++signalsFrame;

        } else {

            // Otherwise, clear the signals and invalidate the signal frame
            // pointer.
            signals = null;
            signalsFrame = -1;
        }

        // //// Step the dynamics. ////

        // Ask each tank to take care of its dynamics.
        for (Tank tank : tanks) {
            tank.update();
        }
    }

    // Render the simulator under its current status.
    public PImage render() {

        pg.beginDraw();

        // Draw background.
        pg.background(BACKGROUND_GRAYSCALE, BACKGROUND_ALPHA);

        // Rely on individual tanks to draw themselves.
        for (Tank tank : tanks) {
            tank.draw(pg);
        }

        pg.endDraw();

        // Return the bitmap rendering.
        return pg.get();
    }

    // Return the tanks contained in this simulator.
    public ArrayList<Tank> getTanks() {

        return tanks;
    }

    // //// Helper methods. ////

    // Add tanks according to the design.
    private void addTanks() {

        // Tank size depends on simulator size.
        float tankSizeX = sizeX / BubbleRenderer.N_TANK_COLUMNS;
        float tankSizeY = sizeY / BubbleRenderer.N_TANK_ROWS;

        // //// Column 0 (Tank 0 - 3). ////

        float tankX = 0.0;

        for (int i = 0; i < BubbleRenderer.N_TANK_ROWS - 1; ++i) {
            float tankY = (i + 0.5) * tankSizeY;
            Tank tank =
                    new Tank(
                        new PVector(tankX, tankY, 0),
                        new PVector(tankSizeX, tankSizeY, 0));
            tanks.add(tank);
        }

        // //// Column 1 (Tank 4 - 8). ////

        tankX += tankSizeX;

        for (int i = 0; i < BubbleRenderer.N_TANK_ROWS; ++i) {
            float tankY = i* tankSizeY;
            Tank tank =
                    new Tank(
                        new PVector(tankX, tankY, 0),
                        new PVector(tankSizeX, tankSizeY, 0));
            tanks.add(tank);
        }

        // //// Column 2 (Tank 9 - 12). ////

        tankX += tankSizeX;

        for (int i = 0; i < BubbleRenderer.N_TANK_ROWS - 1; ++i) {
            float tankY = (i + 0.5) * tankSizeY;
            Tank tank =
                    new Tank(
                        new PVector(tankX, tankY, 0),
                        new PVector(tankSizeX, tankSizeY, 0));
            tanks.add(tank);
        }

        // //// Column 3 (Tank 13 - 17). ////

        tankX += tankSizeX;

        for (int i = 0; i < BubbleRenderer.N_TANK_ROWS; ++i) {
            float tankY = i* tankSizeY;
            Tank tank =
                    new Tank(
                        new PVector(tankX, tankY, 0),
                        new PVector(tankSizeX, tankSizeY, 0));
            tanks.add(tank);
        }

        // //// Column 4 (Tank 18 - 21). ////

        tankX += tankSizeX;

        for (int i = 0; i < BubbleRenderer.N_TANK_ROWS - 1; ++i) {
            float tankY = (i + 0.5) * tankSizeY;
            Tank tank =
                    new Tank(
                        new PVector(tankX, tankY, 0),
                        new PVector(tankSizeX, tankSizeY, 0));
            tanks.add(tank);
        }
    }

    // //////// Member variables. ////////

    private float sizeX;
    private float sizeY;
    private PGraphics pg;
    private ArrayList<Tank> tanks;

    // Signals for multiple frames. Refer to documentation for
    // `BubbleRenderer.getSignals` for description of the structure.
    private short[][] signals;
    // A pointer to current frame of signals.
    private int signalsFrame;

    // //////// Constants. ////////

    private static final float BACKGROUND_GRAYSCALE = 220.0;
    private static final float BACKGROUND_ALPHA = 255.0;
}
