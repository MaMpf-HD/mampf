/**
  This file contains some auxiliary functions used by the different thyme player types.
*/
const thymeUtility = {

  /*
    Mixes all colors in the array "colors" (write colors as hexadecimal, e.g. "#1fe67d").
   */
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

  /*
     Lightens up a given color (given in a string in hexadecimal
     representation "#xxyyzz") such that e.g. black becomes dark grey.
     The higher the value of "factor" the brighter the colors become.
   */
  lightenUp: function(color, factor) {
    const red = Math.floor(((factor - 1) * 255 + Number("0x" + color.substr(5, 2))) / factor);
    const green = Math.floor(((factor - 1) * 255 + Number("0x" + color.substr(3, 2))) / factor);
    const blue = Math.floor(((factor - 1) * 255 + Number("0x" + color.substr(1, 2))) / factor);
    return "#" + thymeUtility.toHexaDecimal(blue) +
                 thymeUtility.toHexaDecimal(green) +
                 thymeUtility.toHexaDecimal(red);
  },

  /*
    Installs a listener which lets the video play/pause when clicked.
   */
  playOnClick() {
    const video = thymeAttributes.video;
    video.addEventListener('click', function() {
      if (video.paused === true) {
        video.play();
      } else {
        video.pause();
      }
    });
  },

  /*
    Renders latex in a given HTML element.
   */
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

  /*
    Convert time in seconds to string of the form H:MM:SS.
   */
  secondsToTime: function(seconds) {
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
  setUpMaxTime(maxTimeID) {
    const video = thymeAttributes.video;
    video.addEventListener('loadedmetadata', function() {
      const maxTime = document.getElementById(maxTimeID);
      maxTime.innerHTML = thymeUtility.secondsToTime(video.duration);
      if (video.dataset.time != null) {
        const time = video.dataset.time;
        video.currentTime = time;
      }
    });
  },

  /*
    Converts a json timestamp into a double value containing the absolute value of seconds.
   */
  timestampToSeconds: function(timestamp) {
    return 3600 * timestamp.hours + 60 * timestamp.minutes + timestamp.seconds + 0.001 * timestamp.milliseconds;
  },

  /*
    Converts a given integer between 0 and 255 into a hexadecimal, s.t. e.g. "15" becomes "0f"
    (instead of just "f") -> needed for correct format.
   */
  toHexaDecimal: function(int) {
    if (int > 15) {
      return int.toString(16);
    } else {
      return "0" + int.toString(16);
    }
  },

};
