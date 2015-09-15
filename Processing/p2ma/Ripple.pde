// ///////////////////////////////////////////////
//
// p2ma (Pi To Master Arduino) | The Living | 2015
//
// ///////////////////////////////////////////////

// Represents a ripple in a coordinate system independent
// of the bubble rasterization.
public class Ripple {

    // //////// Constructors. ////////

    public Ripple(PVector center) {

        this.center = center;
        radii = new float[MAX_CURRENT_NUM_OF_RINGS];
        ringAges = new int[MAX_CURRENT_NUM_OF_RINGS];
        currentNumOfRings = 0;
        totalNumOfRings = 0;
        rippleAge = 0;
    }

    // //////// Methods. ////////

    // //// Public. ////

    // Return the ripple center.
    public PVector getCenter() {

        return center;
    }

    // Return ring radii.
    public float[] getRadii() {

        // Return valid radii only.

        float[] validRadii = new float[currentNumOfRings];
        for(int i = 0; i < currentNumOfRings; ++i) {
            validRadii[i] = radii[i];
        }

        return validRadii;
    }

    // Return ripple's age in frames since its creation.
    public int getRippleAge() {

        return rippleAge;
    }

    // Step the ripple animation by one frame.
    public void update() {

        // If the current number of rings reaches limit or
        // the age of the oldest ring reaches limit, remove
        // the oldest ring.
        if ((currentNumOfRings > MAX_CURRENT_NUM_OF_RINGS) ||
            ((currentNumOfRings > 0) && (ringAges[0] == MAX_RING_AGE))) {

            removeOldestRing();
        }

        // If the limit of total number of rings has not been
        // reached and it is time to spawn a ring, do it.
        if ((totalNumOfRings < MAX_TOTAL_NUM_OF_RINGS) &&
            (rippleAge % RING_SPAWN_INTERVAL) == 0) {

            spawnRing();
        }

        // Updat the radii and ages of the rings.
        for(int i = 0; i < currentNumOfRings; ++i) {

            radii[i] += SPEED;
            ++ringAges[i];
        }

        // Update the age of the ripple.
        ++rippleAge;
    }

    // Draw the ripple onto a given `PGraphics` instance
    // with its current settings. It is supposed to call
    // between a pair of `pg.beginDraw()` and `pg.endDraw()`.
    public void draw(PGraphics pg) {

        pg.fill(RIPPLE_FILL_GRAYSCALE, RIPPLE_FILL_ALPHA);

        // We are drawing from the oldest, i.e. the largest ring
        // so that in case the fill color is opaque, the inner rings
        // are still visible.
        for(int i = 0; i < currentNumOfRings; ++i) {

            float radius = radii[i];

            // The ring gradually grows transparent as it ages,
            // reaching complete transparency at its maximum age.
            float ringStrokeAlpha =
                (1.0 - (float) ringAges[i] / MAX_RING_AGE) * 255.0;

            // The ring gradually grows thinner as it ages.
            int strokeWeight = computeStrokeWeight(ringAges[i]);

            pg.strokeWeight(strokeWeight);
            pg.stroke(RIPPLE_STROKE_GRAYSCALE, ringStrokeAlpha);
            pg.ellipse(center.x, center.y, radius, radius);
        }
    }

    // Determine whether the ripple has died so that further update would be
    // unnecessary.
    public boolean isDead() {

        return (totalNumOfRings == MAX_TOTAL_NUM_OF_RINGS) &&
            (currentNumOfRings == 0);
    }

    // //// Helper functions. ////

    // Spawn a new ring.
    private void spawnRing() {

        // Initialize the new ring's radius and age.
        radii[currentNumOfRings] = INITIAL_RING_RADIUS;
        ringAges[currentNumOfRings] = 0;

        // Update the counters.
        ++currentNumOfRings;
        ++totalNumOfRings;
    }

    // Remove the oldest ring from the ripple.
    private void removeOldestRing() {

        // Since the first entry is the oldest ring, we remove it
        // by shifting all entries to the left by 1.

        for(int i = 0; i < currentNumOfRings - 1; ++i) {
            radii[i] = radii[i + 1];
            ringAges[i] = ringAges[i + 1];
        }

        // Update the counter. No need to update `totalNumOfRings`
        // since it was already spawned.
        --currentNumOfRings;
    }

    // Compute the stroke weight of a ring based on its age.
    // The older a ring is, the thinner its stroke should be.
    private int computeStrokeWeight(float ringAge) {

        return (int) (pow(1.0 - (float) ringAge / MAX_RING_AGE, 4) *
                MAX_RING_STROKE_WEIGHT);
    }

    // //////// Member variales. ////////

    // Center of the ripple.
    private PVector center;
    // The radii of the rings, ordered from oldest to newest.
    // Only the first `currentNumOfRings` entries are meaningful.
    private float[] radii;
    // The ages of rings in frames counting from when the ripple was
    // initially created. Only the first `currentNumOfRings` entries
    // are meaningful.
    private int[] ringAges;
    // Current number of rings.
    private int currentNumOfRings;
    // Total number of rings ever spawned for this ripple.
    private int totalNumOfRings;
    // The current frame since the ripple was created.
    private int rippleAge;

    // //////// Constants. ////////

    // //// Kinematics. ////

    // Number of units that the radius of a ring will increase per frame.
    private static final float SPEED = 10.0;
    // Number of frames between spawning two adjacent rings.
    private static final int RING_SPAWN_INTERVAL = 2;
    // Maximum number of frames a ring can exist for.
    private static final int MAX_RING_AGE = 16;
    // Maximum number of rings ever spawned for a ripple.
    private static final int MAX_TOTAL_NUM_OF_RINGS = 4;
    // Maximum number of rings currently in a ripple.
    private static final int MAX_CURRENT_NUM_OF_RINGS = 4;
    // Initial radius of a newly spawned ring.
    private static final float INITIAL_RING_RADIUS = 1.0;

    // //// Appearance. ////

    private static final float RIPPLE_STROKE_GRAYSCALE = 255.0;
    public static final float RIPPLE_FILL_GRAYSCALE = 0.0;
    public static final float RIPPLE_FILL_ALPHA = 0.0;
    public static final float MAX_RING_STROKE_WEIGHT = 4.0;
}