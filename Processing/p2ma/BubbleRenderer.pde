// ///////////////////////////////////////////////
//
// p2ma (Pi To Master Arduino) | The Living | 2015
//
// ///////////////////////////////////////////////

// An abstract device to render bitmaps with bubbles.
// The rendering target looks like this:
//
//          |----|    |----|
//     |----|  4 |----| 13 |----|
//     |  0 |----|  9 |----| 18 |
//     |----|  5 |----| 14 |----|
//     |  1 |----| 10 |----| 19 |
//     |----|  6 |----| 15 |----|
//     |  2 |----| 11 |----| 20 |
//     |----|  7 |----| 16 |----|
//     |  3 |----| 12 |----| 21 |
//     |----|  8 |----| 17 |----|
//          |----|    |----|
//
// Within each tank, the nozzles and the signal bits are ordered like this:
//
//                                   -----------------------------------------
// Pixels                            |  0|  1|  2|  3|  4|  5|  6|  7|  8|  9|
//                                   -----------------------------------------
//                                     __  __  __  __  __  __  __  __  __  __
// Nozzles                            =||==||==||==||==||==||==||==||==||==||=
//                                      0   1   2   3   4   5   6   7   8   9
//
// Signal    -----------------------------------------------------------------
// bits      | 15| 14| 13| 12| 11| 10|  9|  8|  7|  6|  5|  4|  3|  2|  1|  0|
//           -----------------------------------------------------------------
//
public class BubbleRenderer {

    // //////// Constructors. ////////

    public BubbleRenderer(float threshold, boolean neg) {

        // `sizeX` indicates the number of nozzles in a row, and
        // `sizeY` indicates the number of bubbles in a column.
        int sizeX = N_NOZZLES_PER_TANK * N_TANK_COLUMNS;
        int sizeY = N_BUBBLE_ROWS_PER_TANK * N_TANK_ROWS;

        pg = createGraphics(sizeX, sizeY);
        this.threshold = threshold;
        this.neg = neg;
    }

    // //////// Methods. ////////

    // //// Public. ////

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
    //     - image:    The bitmap image to be rendered with bubbles.
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

    // Create the signals to send to the simulator to create bubbles.
    //
    // Parameters:
    //
    //     - image: The bitmap image to be rendered with bubbles.
    //
    // Returns:
    //
    //     A 2D array of short integers (16 bits) representing a sequence
    //     of signals to send to the simulator over multiple frames:
    //     `signals[frame]` contains the signals to the simulator at
    //     Frame `frame`. `signals[frame][tank]` is the signal to
    //     Tank `tank` at Frame `frame`. One frame corresponds to one
    //     bubble row.
    public short[][] getSignals(PImage image) {

        // Compute the mask for the image.
        boolean[][] mask = getMask(image);

        // Convert the mask into signals that generate rows of bubbles
        // to render the image.
        short[][] signals = new short[N_BUBBLE_ROWS_PER_TANK][N_TANKS];

        // The image coordinates goes from top to bottom (+y) and
        // left to right (+x).

        // Within each tank, the first bubble row represents pixels with
        // smaller y, and this row gets emitted first.
        for (int frame = 0; frame < N_BUBBLE_ROWS_PER_TANK; ++frame) {

            for (int tank = 0; tank < N_TANKS; ++tank) {

                // Get the start position of the mask region corresponding
                // to `tank`.
                int[] start = getTankMappingStart(tank);

                // The y coordinate of the pixels in the mask to be rendered
                // by bubbles in Row `frame`.
                int y = start[1] + frame;

                short signal = 0;

                // As the drawing at the top of this file shows, the
                // signal bits and the nozzles have reversed orders, while the
                // latter is consistent with the pixels in the mask. We thus
                // start from the rightmost nozzle's signal bit, which will be
                // eventually shifted to the most significant bit (Bit 9).
                for (int nozzle = N_NOZZLES_PER_TANK - 1; nozzle >= 0; --nozzle) {

                    // The x coordinate of the pixel to be rendered by
                    // Nozzle `nozzle`.
                    int x = start[0] + nozzle;
                    // Set Bit 0, which is temporarily the signal bit for
                    // Nozzle `nozzle`, to 1.
                    if (mask[y][x]) signal |= 1;

                    signal <<= 1;
                }
                signal >>= 1;

                signals[frame][tank] = signal;
            }
        }

        return signals;
    }

    // //// Helper methods. ////

    // Get the start coordinates of a region in the mask corresponding to
    // a tank. See drawings at the top.
    private int[] getTankMappingStart(int tank) {

        int startX;
        int startY;

        if (tank >= 0 && tank < 4) {

            startX = 0;
            startY = N_BUBBLE_ROWS_PER_TANK * (tank - 0) + N_BUBBLE_ROWS_PER_TANK / 2;

        } else if (tank >= 4 && tank < 9) {

            startX = N_NOZZLES_PER_TANK;
            startY = N_BUBBLE_ROWS_PER_TANK * (tank - 4);

        } else if (tank >= 9 && tank < 13) {

            startX = N_NOZZLES_PER_TANK * 2;
            startY = N_BUBBLE_ROWS_PER_TANK * (tank - 9) + N_BUBBLE_ROWS_PER_TANK / 2;

        } else if (tank >= 13 && tank < 18) {

            startX = N_NOZZLES_PER_TANK * 3;
            startY = N_BUBBLE_ROWS_PER_TANK * (tank - 13);

        } else if (tank >= 18 && tank < 22) {

            startX = N_NOZZLES_PER_TANK * 4;
            startY = N_BUBBLE_ROWS_PER_TANK * (tank - 18) + N_BUBBLE_ROWS_PER_TANK / 2;

        } else {

            startX = -1;
            startY = -1;
        }

        int[] start = {startX, startY};

        return start;
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

    // //// Appearance. ////

    public static final float BACKGROUND_GRAYSCALE = 255.0;
    public static final float BACKGROUND_ALPHA = 255.0;
    public static final float ELEM_FILL_GRAYSCALE = 0.0;
    public static final float ELEM_FILL_ALPHA = 0.0;
    public static final float ELEM_STROKE_GRAYSCALE = 0.0;
    public static final float ELEM_STROKE_ALPHA = 255.0;

    // //// Design. See drawings at the top. ////

    public static final int N_TANKS = 22;
    public static final int N_TANK_COLUMNS = 5;
    public static final int N_TANK_ROWS = 5;
    public static final int N_NOZZLES_PER_TANK = 10;
    public static final int N_BUBBLE_ROWS_PER_TANK = 10;
}