import { AnnotationCategoryToggle } from "./components/annotation_category_toggle";
import { mixColors } from "./utility";

/**
 * Objects of this class represent heatmaps. It provides the function draw() which
 * draws the heatmap to the thyme player.
 */
export class Heatmap {
  static RADIUS = 10; // this number adjusts the radius of the peaks of the heatmap
  static MAX_HEIGHT = 0.25; // this number adjusts the maximum heights of the heatmap peaks

  /*
   * id = The ID of the HTML element to which the heatmap will be appended.
   */
  constructor(id) {
    this.heatmap = $("#" + id);
    this.categories = [];
  }

  draw() {
    if (!thymeAttributes.annotations) {
      return;
    }
    this.heatmap.empty();

    /*
       variable definitions
    */
    // We assume a slightly bigger width to be able to display sine waves
    // also at the beginning and the end of the timeline.
    const stickOutWidthOneSided = Heatmap.RADIUS;
    const thresh = 20; // a small additional width to avoid the heatmap to be cut off
    const seekBarWidth = thymeAttributes.seekBar.element.clientWidth;
    const width = seekBarWidth + 2 * stickOutWidthOneSided + thresh;
    const stretch = seekBarWidth / (seekBarWidth + 4 * stickOutWidthOneSided + thresh);

    const maxHeight = thymeAttributes.video.clientHeight * Heatmap.MAX_HEIGHT;
    this.heatmap.css("top", -maxHeight - 11); // vertical offset

    const numDivisons = width + 4 * Heatmap.RADIUS + 1;
    /* An array for each pixel on the timeline. The indices of this array should be thought
       of the x-axis of the heatmap's graph, while its entries should be thought of its
       values on the y-axis. */
    let pixels = new Array(numDivisons).fill(0);
    /* amplitude should be calculated with respect to all annotations
       (even those which are not shown). Otherwise the peaks increase
       when turning off certain annotations because the graph has to be
       normed. Therefore we need this additional "pixelsAll" array. */
    let pixelsAll = new Array(numDivisons).fill(0);
    /* for any visible annotation, this array contains its color (needed for the calculation
       of the heatmap color) */
    let colors = [];

    /*
       data calculation
    */
    for (const a of thymeAttributes.annotations) {
      const valid = this.#isValidCategory(a.category)
        && AnnotationCategoryToggle.isChecked(a.category);

      if (valid) {
        colors.push(a.category.color);
      }
      const time = a.seconds;
      const position = Math.round(stretch * width * (time / thymeAttributes.video.duration));
      for (let x = position - Heatmap.RADIUS; x <= position + Heatmap.RADIUS; x++) {
        let y = Heatmap.#sinX(x, position, Heatmap.RADIUS);
        pixelsAll[x + Heatmap.RADIUS] += y;
        if (valid) {
          pixels[x + Heatmap.RADIUS] += y;
        }
      }
    }
    const maxValue = Math.max(...pixelsAll);
    const amplitude = maxValue != 0 ? maxHeight * (1 / maxValue) : 0;

    /*
       Construct heatmap SVG
    */
    let pointsStr = `0,${maxHeight} `;
    for (let x = 0; x < pixels.length; x++) {
      pointsStr += `${x},${maxHeight - amplitude * pixels[x]} `;
    }
    pointsStr += `${width},${maxHeight}`;

    const heatmapStr = `<svg width="${(width - stickOutWidthOneSided - thresh)}"
                             height="${maxHeight}">
                         <polyline points="${pointsStr}"
                           style="fill:${mixColors(colors)};
                           fill-opacity:0.4;
                           stroke:black;
                           stroke-width:1"/>
                       </svg>`;
    this.heatmap.append(heatmapStr);
  }

  addCategory(category) {
    if (this.categories.includes(category)) {
      return;
    }
    this.categories.push(category);
  }

  removeCategory(category) {
    this.categories = this.categories.filter(c => c !== category);
  }

  /*
    AUXILIARY METHODS
  */

  #isValidCategory(category) {
    return this.categories.includes(category);
  }

  /* A modified sine function for building nice peaks around the marker positions.

       x = insert value
       position = the position of the maximum value
  */
  static #sinX(x, position) {
    return (1 + Math.sin(Math.PI / Heatmap.RADIUS * (x - position) + Math.PI / 2)) / 2;
  }
}
