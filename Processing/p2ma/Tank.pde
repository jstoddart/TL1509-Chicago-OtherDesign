// ///////////////////////////////////////////////
//
// p2ma (Pi To Master Arduino) | The Living | 2015
//
// ///////////////////////////////////////////////

// Represents a tank and the nozzles within it.
// Note that the coordinate system the tank is in is consistent with that of
// the window GUI, meaning that x axis points to the right and y axis
// points up.
public class Tank {

    // //////// Constructors. ////////

    // Create a tank at a give position of a given size.
    public Tank(PVector position, PVector size) {

        this.position = position;
        this.size = size;

        bubbles = new ArrayList<Bubble>();
    }

    // //////// Methods. ////////

    // //// Public. ////

    // Draw the tank and the nozzles and bubbles in it. It is supposed to be
    // called between a pair of `pg.beginDraw` and `pg.endDraw`.
    public void draw(PGraphics pg) {

        // Draw tank.
        pg.fill(TANK_FILL_GRAYSCALE, TANK_FILL_ALPHA);
        pg.stroke(TANK_STROKE_GRAYSCALE, TANK_STROKE_ALPHA);
        pg.strokeWeight(TANK_STROKE_WEIGHT);
        pg.rect(position.x, position.y, size.x, size.y);

        // TODO Draw nozzles.

        // Draw bubbles.
        for (Bubble bubble : bubbles) {
            bubble.draw(pg);
        }
    }

    // Get the y coordinate of the tank top, where the bubbles are destroyed.
    public float getTop() {

        return position.y;
    }

    // Get the center coordinates of the tank.
    public PVector getCenter() {

        float topX = position.x;
        float topY = position.y;
        float sizeX = size.x;
        float sizeY = size.y;

        PVector center = new PVector(topX + sizeX * 0.5, topY + sizeY * 0.5);
        return center;
    }

    // Update the bubbles in the tank.
    public void update() {

        // Update the dynamics of each bubble.
        for (Bubble bubble : bubbles) {
            bubble.update();
        }

        // Remove bubbles that are destroyed upon reaching the top of the tank.
        for (int i = bubbles.size() - 1; i >= 0; --i) {
            if (bubbles.get(i).isDead()) {
                bubbles.remove(i);
            }
        }
    }

    // Send a signals to the nozzles of this tank. The structure and mapping
    // of the signal bits and the nozzles are depicted by the drawings in
    // `BubbleRenderer.pde`.
    private void send(short signal) {

        // Compute the bubble radius, assuming they horizontally fill up the
        // space in a tank except for the margins between nozzles and walls.
        float bubbleSize =
            (1.0 - NOZZLES_MARGIN_NORMALIZED * 2) /
            BubbleRenderer.N_NOZZLES_PER_TANK / 2 * size.x;

        // Active nozzles based on their corresponding signal bits.
        for (int nozzle = 0; nozzle < BubbleRenderer.N_NOZZLES_PER_TANK; ++nozzle) {

            if (((signal >> nozzle) & 1) == 1) {

                // Emit a bubble at the nozzle's position if its corresponding
                // signal bit is on.
                PVector position = getNozzlePosition(nozzle);
                Bubble bubble = new Bubble(this, position, bubbleSize);
                bubbles.add(bubble);
            }
        }
    }

    // Get the position of the tank.
    public PVector getPosition() {

        return position;
    }

    // Get the size of the tank.
    public PVector getSize() {

        return size;
    }

    // Get all the bubbles in the tank.
    public ArrayList<Bubble> getBubbles() {

        return bubbles;
    }

    // //// Helper methods. ////

    private PVector getNozzlePosition(int nozzle) {

        float nozzleWidthNormalized =
            (1.0 - NOZZLES_MARGIN_NORMALIZED * 2) / BubbleRenderer.N_NOZZLES_PER_TANK;

        float leftNormalized =
            NOZZLES_MARGIN_NORMALIZED +
            ((1.0 - NOZZLES_MARGIN_NORMALIZED * 2) / BubbleRenderer.N_NOZZLES_PER_TANK) * nozzle +
            nozzleWidthNormalized * 0.5;

        float x = position.x + size.x * leftNormalized;
        float y = position.y + size.y;

        return new PVector(x, y, 0);
    }

    // //////// Member variables. ////////

    private PVector position;
    private PVector size;
    private ArrayList<Bubble> bubbles;

    // //////// Constants. ////////

    // The distance between the left wall and the leftmost nozzle, normalized
    // to the width of the tank.
    private static final float NOZZLES_MARGIN_NORMALIZED = 0.04;

    private static final float TANK_FILL_GRAYSCALE = 255.0;
    private static final float TANK_FILL_ALPHA = 255.0;
    private static final float TANK_STROKE_GRAYSCALE = 160.0;
    private static final float TANK_STROKE_ALPHA = 255.0;
    private static final float TANK_STROKE_WEIGHT = 8.0;
}