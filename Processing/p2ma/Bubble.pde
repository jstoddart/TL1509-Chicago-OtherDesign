// ///////////////////////////////////////////////
//
// p2ma (Pi To Master Arduino) | The Living | 2015
//
// ///////////////////////////////////////////////

// Represent a bubble emitted from a nozzle.
// Note that the coordinate system the bubble is in is consistent with that of
// the window GUI, meaning that x axis points to the right and y axis
// points up.
public class Bubble {

    // //////// Constructors. ////////

    // Create a bubble emitted in the given tank at the given position.
    public Bubble(Tank tank, PVector position, float radius) {

        this.tank = tank;
        this.radius = radius;

        // Dynamics.
        this.position = position;
        this.velocity = new PVector(0.0, INITIAL_VELOCITY_Y, 0.0);
        this.acceleration = new PVector(0.0, ACCELERATION_Y, 0.0);
    }

    // //////// Methods. ////////

    // Draw the bubble. It is supposed to be called between a pair of
    // `pg.beginDraw` and `pg.endDraw`.
    public void draw(PGraphics pg) {

        pg.fill(BUBBLE_FILL_GRAYSCALE, BUBBLE_FILL_ALPHA);
        pg.stroke(BUBBLE_STROKE_GRAYSCALE, BUBBLE_STROKE_ALPHA);
        pg.strokeWeight(BUBBLE_STROKE_WEIGHT);
        // pg.ellipse(position.x, position.y, radius, radius);
        pg.rect(position.x - radius / 2, position.y - radius / 2, radius, radius);
    }

    // Check if the bubble is dead (and thus can be removed).
    public boolean isDead() {

        // A bubble not belonging to any tank cannot survive!
        if (tank == null) return true;

        // The bubble bursts at the top of the tank.
        return position.y - radius <= tank.getTop();
    }

    // Update the dynamics of the bubble.
    public void update() {

        velocity.add(acceleration);
        position.add(velocity);
    }

    // //////// Member variables. ////////

    // The tank this bubble is emitted in.
    private Tank tank;
    // Radius of the bubble.
    private float radius;
    // Position of the bubble in world (simulator) space.
    private PVector position;
    // The discrete velocity, i.e. position delta between two time steps.
    // No need to multiply by time step.
    private PVector velocity;
    // The discrete acceleration, i.e. velocity delta between two time steps.
    // No need to multiply by time step.
    private PVector acceleration;

    // //////// Constants. ////////

    // The bubble only moves up. Since we are using the coordinate system of
    // window GUI, up is the negative y axis.
    private static final float INITIAL_VELOCITY_Y = -6.0;
    private static final float ACCELERATION_Y = -0.0;

    private static final float BUBBLE_FILL_GRAYSCALE = 0.0;
    private static final float BUBBLE_FILL_ALPHA = 100.0;
    private static final float BUBBLE_STROKE_GRAYSCALE = 100.0;
    private static final float BUBBLE_STROKE_ALPHA = 150.0;
    private static final float BUBBLE_STROKE_WEIGHT = 1.0;
}
