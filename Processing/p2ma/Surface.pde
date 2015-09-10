// ///////////////////////////////////////////////
//
// p2ma (Pi To Master Arduino) | The Living | 2015
//
// ///////////////////////////////////////////////

// Represents the surface on which all ripples expand.
public class Surface {

    // //////// Constructors. ////////

    public Surface(int sizeX, int sizeY) {

        ripples = new ArrayList<Ripple>();
        pg = createGraphics(sizeX, sizeY);
    }

    // //////// Methods. ////////

    // //// Public. ////

    // Add a ripple to the surface.
    public void addRipple(Ripple ripple) {

        ripples.add(ripple);
    }

    // Step all ripples' animation by one frame and remove dead ripples.
    public void update() {

        for(Ripple ripple : ripples) {
            ripple.update();
        }

        for(int i = ripples.size() - 1; i >= 0; --i) {
            if (ripples.get(i).isDead()) {
                ripples.remove(i);
            }
        }
    }

    // Render an image of the surface consisting of its background and
    // all the ripples.
    public PImage render() {

        pg.beginDraw();

        // Draw the background.
        pg.background(BACKGROUND_GRAYSCALE, BACKGROUND_ALPHA);

        // Draw every ripple.
        for(Ripple ripple : ripples) {
            ripple.draw(pg);
        }

        pg.endDraw();

        // Return the image rendered with `pg`.
        return pg.get();
    }

    // //////// Member variables. ////////

    // All ripples on the surface.
    private ArrayList<Ripple> ripples;
    // The graphpics context for drawing this surface.
    private PGraphics pg;

    // //////// Constants. ////////

    public static final float BACKGROUND_GRAYSCALE = 0.0;
    public static final float BACKGROUND_ALPHA = 255.0;
}
