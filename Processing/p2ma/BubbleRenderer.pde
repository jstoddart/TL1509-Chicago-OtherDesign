// ///////////////////////////////////////////////
//
// p2ma (Pi To Master Arduino) | The Living | 2015
//
// ///////////////////////////////////////////////

// An abstract device to render bitmaps with bubbles.
public class BubbleRenderer {

    // //////// Constructors. ////////

    // `sizeX` typically indicates the number of nozzles in a row, and
    // `sizeY` for the number of bubbles in a column.
    public BubbleRenderer(int sizeX, int sizeY, float threshold, boolean neg) {

        pg = createGraphics(sizeX, sizeY);
        this.threshold = threshold;
        this.neg = neg;
    }

    // //////// Methods. ////////

    // Compute the mask for a given grayscale bitmap for bubble rendering.
    // 
    // Parameters:
    //
    //    - image:     A grayscale bitmap.
    //
    // Returns:
    // 
    //     A 2-dimensional boolean array as the mask of the same size as the
    //     renderer's size. A `true` entry indicates a bubble at the location
    //     specified by the indices [y][x].
    public boolean[][] getMask(PImage image) {

        // Resample the given image to the size of this renderer with
        // the convenience offered by `PGraphics`.
        pg.beginDraw();
        pg.image(image, 0, 0, pg.width, pg.height);
        pg.endDraw();
        PImage resampledImage = pg.get();

        // Create a mask the same size as the resampled image.
        boolean[][] mask = new boolean[pg.height][pg.width];

        for(int y = 0; y < pg.height; ++y) {
            for(int x = 0; x < pg.width; ++x) {
                int i = pg.width * y + x;
                // Usage of `threshold` depends on `neg`.
                if (neg) {
                    mask[y][x] = (resampledImage.pixels[i] < threshold);
                } else {
                    mask[y][x] = (resampledImage.pixels[i] >= threshold);
                }
            }
        }

        return mask;
    }

    // Visialize the bubble render on screen.
    //
    // Parameters:
    //
    //     - image:    The bitmap image to render with bubbles.
    //     - elemName: The geometry element to represent a bubble. Supported
    //                 values include "rect" (for rectangles) and "circle"
    //                 (for circles).
    //     - cellSize: Size of the cell containing a geometry element.
    //     - elemSize: Size of the element. For rectangle this is its side
    //                 length, and for circles its diameter.
    //
    // Returns:
    //
    //     A bitmap of the render.     
    public PImage render(
        PImage image, String elemName, int cellSize, int elemSize) {

        boolean[][] mask = getMask(image);

        PGraphics pg =
            createGraphics(
                cellSize * this.pg.width, cellSize * this.pg.height);

        pg.beginDraw();

        pg.background(BACKGROUND_GRAYSCALE, BACKGROUND_ALPHA);

        pg.fill(ELEM_FILL_GRAYSCALE, ELEM_FILL_ALPHA);
        pg.stroke(ELEM_STROKE_GRAYSCALE, ELEM_STROKE_ALPHA);

        for(int cellY = 0; cellY < this.pg.height; ++cellY) {
            for(int cellX = 0; cellX < this.pg.width; ++cellX) {
                if (mask[cellY][cellX]) {

                    float x = cellX * cellSize;
                    float y = cellY * cellSize;

                    if (elemName == "rect") {

                        pg.rect(x, y, elemSize, elemSize);

                    } else if (elemName == "circle") {

                        pg.ellipse(
                            x + cellX * 0.5, y + cellY * 0.5,
                            elemSize / 2.0, elemSize / 2.0);
                    }
                }
            }
        }

        pg.endDraw();

        return pg.get();
    }

    // signals[tank_id][frame]
    public short[][] signalsTransient(PImage image) {

        // TODO

        return null;
    }

    // signals[tank_id][frame]
    public short[][] signalsContinuous(PImage image) {

        // TODO

        return null;
    }

    // //////// Member variables. ////////

    // An internal context to resample given bitmaps.
    private PGraphics pg;
    // A value to determine whether there should be a bubble
    // at a position or not. Works with `neg`.
    float threshold;
    // If `false`, there will be a bubble at a position if
    // the grayscale value after resampling is greather than
    // or equal to `threshold`. If `true`, that value should be
    // smaller than `threshold`.
    boolean neg;

    // //////// Constants. ////////

    public static final float BACKGROUND_GRAYSCALE = 255.0;
    public static final float BACKGROUND_ALPHA = 255.0;
    public static final float ELEM_FILL_GRAYSCALE = 0.0;
    public static final float ELEM_FILL_ALPHA = 0.0;
    public static final float ELEM_STROKE_GRAYSCALE = 0.0;
    public static final float ELEM_STROKE_ALPHA = 255.0;
}
