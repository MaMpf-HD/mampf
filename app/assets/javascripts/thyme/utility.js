/*
  This namespace contains some auxiliary functions used by the different thyme player types.
*/
var thymeUtility = {

  /* returns a certain color for every annotation with respect to the annotations
     category (in the feedback view this gives more information than the original color). */
  annotationColor: function(cat) {
    switch (cat) {
      case "note":
        return "#44ee11"; //green
      case "content":
        return "#eeee00"; //yellow
      case "mistake":
        return "#ff0000"; //red
      case "presentation":
        return "#ff9933"; //orange
    }
  },

  annotationIndex: function(annotation) {
    for (let i = 0; i < thymeAttributes.annotations.length; i++) {
      if (thymeAttributes.annotations[i].id == annotation.id) {
        return i;
      }
    }
  },

  // sorts all annotations according to their timestamp
  annotationSort: function() {
    if (thymeAttributes.annotations === null) {
      return;
    }
    thymeAttributes.annotations.sort(function(ann1, ann2) {
      const t1 = thymeUtility.timestampToMillis(ann1.timestamp);
      const t2 = thymeUtility.timestampToMillis(ann2.timestamp)
      return t1 - t2;
    });
  },

  // mixes all colors in the array "colors" (write colors as hexadecimal, e.g. "#1fe67d").
  colorMixer: function(colors) {
    let n = colors.length;
    let red = 0;
    let green = 0;
    let blue = 0;
    for (let i = 0; i < n; i++) {
      red += Number("0x" + colors[i].substr(5, 2));
      green += Number("0x" + colors[i].substr(3, 2));
      blue += Number("0x" + colors[i].substr(1, 2));
    }
    red = Math.max(0, Math.min(255, Math.round(red / n)));
    green = Math.max(0, Math.min(255, Math.round(green / n)));
    blue = Math.max(0, Math.min(255, Math.round(blue / n)));
    return "#" + thymeUtility.toHexaDecimal(blue) +
                 thymeUtility.toHexaDecimal(green) +
                 thymeUtility.toHexaDecimal(red);
  },

  /* lightens up a given color (given in a string in hexadecimal
     representation "#xxyyzz") such that e.g. black becomes dark grey.
     The higher the value of "factor" the brighter the colors become. */
  lightenUp: function(color, factor) {
    const red = Math.floor(((factor - 1) * 255 + Number("0x" + color.substr(5, 2))) / factor);
    const green = Math.floor(((factor - 1) * 255 + Number("0x" + color.substr(3, 2))) / factor);
    const blue = Math.floor(((factor - 1) * 255 + Number("0x" + color.substr(1, 2))) / factor);
    return "#" + thymeUtility.toHexaDecimal(blue) +
                 thymeUtility.toHexaDecimal(green) +
                 thymeUtility.toHexaDecimal(red);
  },

  // renders latex in a given HTML element
  renderLatex: function(element) {
    renderMathInElement(element, {
      delimiters: [
        {
          left: '$$',
          right: '$$',
          display: true
        }, {
          left: '$',
          right: '$',
          display: false
        }, {
          left: '\\(',
          right: '\\)',
          display: false
        }, {
          left: '\\[',
          right: '\\]',
          display: true
        }
      ],
      throwOnError: false
    });
  },

  // convert time in seconds to string of the form H:MM:SS
  secondsToTime: function(seconds) {
    let date = new Date(null);
    date.setSeconds(seconds);
    return date.toISOString().substr(12, 7);
  },

  // converts a json timestamp to a double containing the absolute count of millitseconds
  timestampToMillis: function(timestamp) {
    return 3600 * timestamp.hours + 60 * timestamp.minutes + timestamp.seconds + 0.001 * timestamp.milliseconds;
  },

  /* converts a given integer between 0 and 255 into a hexadecimal, s.t. e.g. "15" becomes "0f"
     (instead of just "f") -> needed for correct format */
  toHexaDecimal: function(int) {
    if (int > 15) {
      return int.toString(16);
    } else {
      return "0" + int.toString(16);
    }
  },

};