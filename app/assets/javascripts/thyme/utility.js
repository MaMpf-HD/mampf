/**
  This file contains some auxiliary functions used by the different thyme player types.
*/
const thymeUtility = {

  /*
    Mixes all colors in the array "colors" (write colors as hexadecimal, e.g. "#1fe67d").
   */
  mixColors: function (colors) {
    let red = 0;
    let green = 0;
    let blue = 0;
    for (let color of colors) {
      red += Number("0x" + color.substr(5, 2));
      green += Number("0x" + color.substr(3, 2));
      blue += Number("0x" + color.substr(1, 2));
    }
    const n = colors.length;
    red = Math.max(0, Math.min(255, Math.round(red / n)));
    green = Math.max(0, Math.min(255, Math.round(green / n)));
    blue = Math.max(0, Math.min(255, Math.round(blue / n)));
    return "#" + thymeUtility.toHexaDecimal(blue)
      + thymeUtility.toHexaDecimal(green)
      + thymeUtility.toHexaDecimal(red);
  },

  /*
    Convert given dataURL to Blob, used for converting screenshot canvas to png.
   */
  dataURLtoBlob: function (dataURL) {
    // Decode the dataURL
    const binary = atob(dataURL.split(",")[1]);
    // Create 8-bit unsigned array
    let array = [];
    for (let i = 0; i < binary.length; i++) {
      array.push(binary.charCodeAt(i));
    }
    // Return our Blob object
    return new Blob([new Uint8Array(array)], {
      type: "image/png",
    });
  },

  /*
     Lightens up a given color (given in a string in hexadecimal
     representation "#xxyyzz") such that e.g. black becomes dark grey.
     The higher the value of "factor" the brighter the colors become.
   */
  lightenUp: function (color, factor) {
    const red = Math.floor(((factor - 1) * 255 + Number("0x" + color.substr(5, 2))) / factor);
    const green = Math.floor(((factor - 1) * 255 + Number("0x" + color.substr(3, 2))) / factor);
    const blue = Math.floor(((factor - 1) * 255 + Number("0x" + color.substr(1, 2))) / factor);
    return "#" + thymeUtility.toHexaDecimal(blue)
      + thymeUtility.toHexaDecimal(green)
      + thymeUtility.toHexaDecimal(red);
  },

  /*
    Installs a listener which lets the video play/pause when clicked.
   */
  playOnClick: function () {
    const video = thymeAttributes.video;
    video.addEventListener("click", function () {
      if (video.paused) {
        video.play();
      }
      else {
        video.pause();
      }
    });
  },

  /*
    Renders latex in a given HTML element.
   */
  renderLatex: function (element) {
    renderMathInElement(element, {
      delimiters: [
        {
          left: "$$",
          right: "$$",
          display: true,
        }, {
          left: "$",
          right: "$",
          display: false,
        }, {
          left: "\\(",
          right: "\\)",
          display: false,
        }, {
          left: "\\[",
          right: "\\]",
          display: true,
        },
      ],
      throwOnError: false,
    });
  },

  /*
    Convert time in seconds to string of the form H:MM:SS.
   */
  secondsToTime: function (seconds) {
    let date = new Date(null);
    date.setSeconds(seconds);
    return date.toISOString().substr(12, 7);
  },

  /*
    Sets up the label on the right side of the seek bar which displays
    the maximum time of the video.
    (In order to make this work, we have to wait for the video's metadata
    to be loaded.)
   */
  setUpMaxTime: function (maxTimeId) {
    const video = thymeAttributes.video;
    video.addEventListener("loadedmetadata", function () {
      const maxTime = document.getElementById(maxTimeId);
      maxTime.innerHTML = thymeUtility.secondsToTime(video.duration);
      if (video.dataset.time) {
        const time = video.dataset.time;
        video.currentTime = time;
      }
    });
  },

  /*
    Converts a json timestamp into a double value containing the absolute value of seconds.
   */
  timestampToSeconds: function (timestamp) {
    return 3600 * timestamp.hours + 60 * timestamp.minutes + timestamp.seconds + 0.001 * timestamp.milliseconds;
  },

  /*
    Converts a given integer between 0 and 255 into a hexadecimal, s.t. e.g. "15" becomes "0f"
    (instead of just "f") -> needed for correct format.
   */
  toHexaDecimal: function (integer) {
  	return integer.toString(16).padStart(2, "0");
  },

};
