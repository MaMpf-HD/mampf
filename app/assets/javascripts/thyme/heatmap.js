/**
 * Objects of this class represent heatmaps. It provides the function draw() which
 * draws the heatmap to the thyme player.
 */
class Heatmap {

  static RADIUS = 10; // this number adjusts the radius of the peaks of the heatmap

  /*
    categories = an array which contains all the categories (i.e. the string representing
                 the categories) that should be displayed in the heatmap.
  */
  constructor(categories) {
    this.categories = categories;
  }

  draw() {
    if (thymeAttributes.annotations === null) {
      return;
    }
    $('#heatmap').empty();

    /*
       variable definitions
    */
    const width = thymeAttributes.seekBar.element.clientWidth +
                  2 * Heatmap.RADIUS - 35; // width of the video timeline
    const maxHeight = video.clientHeight / 4; // the peaks of the graph should not extend maxHeight
    /* An array for each pixel on the timeline. The indices of this array should be thought
       of the x-axis of the heatmap's graph, while its entries should be thought of its
       values on the y-axis. */
    let pixels = new Array(width + 2 * Heatmap.RADIUS + 1).fill(0);
    /* amplitude should be calculated with respect to all annotations
       (even those which are not shown). Otherwise the peaks increase
       when turning off certain annotations because the graph has to be
       normed. Therefore we need this additional "pixelsAll" array. */
    let pixelsAll = new Array(width + 2 * Heatmap.RADIUS + 1).fill(0);
    /* for any visible annotation, this array contains its color (needed for the calculation
       of the heatmap color) */
    let colors = [];

    /*
       data calculation
    */
    for (const a of thymeAttributes.annotations) {
      const valid = this.#validCategory(a.category) &&
                    a.category !== "mistake"; // <- don't include mistake annotations
      if (valid === true) {
        colors.push(thymeUtility.annotationColor(a.category));
      }
      const time = thymeUtility.timestampToSeconds(a.timestamp);
      const position = Math.round(width * (time / video.duration));
      for (let x = position - Heatmap.RADIUS; x <= position + Heatmap.RADIUS; x++) {
        let y = Heatmap.#sinX(x, position, Heatmap.RADIUS);
        pixelsAll[x + Heatmap.RADIUS] += y;
        if (valid === true) {
          pixels[x + Heatmap.RADIUS] += y;
        }
      }
    }
    const maxValue = Math.max.apply(Math, pixelsAll);
    const amplitude = maxHeight * (1 / maxValue);

    /*
       draw heatmap
    */
    let pointsStr = "0," + maxHeight + " ";
    for (let x = 0; x < pixels.length; x++) {
      pointsStr += x + "," + (maxHeight - amplitude * pixels[x]) + " ";
    }
    pointsStr += "" + width + "," + maxHeight;
    const heatmapStr = '<svg width=' + (width + 35) + ' height="' + maxHeight + '">' +
                         '<polyline points="' + pointsStr + '"' +
                           'style="fill:' + thymeUtility.colorMixer(colors) + ';' +
                           'fill-opacity:0.4;' +
                           'stroke:black;' +
                           'stroke-width:1"/>' +
                       '</svg>';
    $('#heatmap').append(heatmapStr);
    const offset = $('#heatmap').parent().offset().left - Heatmap.RADIUS + 79;
    $('#heatmap').offset({ left: offset });
    $('#heatmap').css('top', -maxHeight - 4); // vertical offset
  }



  /*
    AUXILIARY METHODS
  */

  #validCategory(category) {
    return this.categories.includes(category);
  }

  /* A modified sine function for building nice peaks around the marker positions.
  
       x = insert value
       position = the position of the maximum value
  */
  static #sinX(x, position) {
    return (1 + Math.sin(Math.PI / Heatmap.RADIUS * (x - position) + Math.PI / 2)) / 2;
  }

};