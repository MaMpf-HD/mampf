/**
 * Mixes all colors in the array "colors"
 * (write colors as hexadecimal, e.g. "#1fe67d").
 */
export function mixColors(colors) {
  let red = 0;
  let green = 0;
  let blue = 0;
  for (const color of colors) {
    red += Number("0x" + color.substr(5, 2));
    green += Number("0x" + color.substr(3, 2));
    blue += Number("0x" + color.substr(1, 2));
  }
  const n = colors.length;
  red = Math.max(0, Math.min(255, Math.round(red / n)));
  green = Math.max(0, Math.min(255, Math.round(green / n)));
  blue = Math.max(0, Math.min(255, Math.round(blue / n)));
  return "#" + toHexaDecimal(blue) + toHexaDecimal(green) + toHexaDecimal(red);
}

/**
 * Converts a data URL to a Blob object.
 *
 * This is used for converting a screenshot canvas to a PNG Blob.
 */
export function dataURLtoBlob(dataURL) {
  // Decode the dataURL
  const binary = atob(dataURL.split(",")[1]);
  // Create 8-bit unsigned array
  const array = [];
  for (let i = 0; i < binary.length; i++) {
    array.push(binary.charCodeAt(i));
  }
  // Return our Blob object
  return new Blob([new Uint8Array(array)], {
    type: "image/png",
  });
}

/**
 * Lightens up a given color (given in a string in hexadecimal),
 * such that e.g. black becomes dark grey.
 *
 * The higher the value of "factor" the brighter the colors become.
 */
export function lightenUp(color, factor) {
  const red = Math.floor(((factor - 1) * 255 + Number("0x" + color.substr(5, 2))) / factor);
  const green = Math.floor(((factor - 1) * 255 + Number("0x" + color.substr(3, 2))) / factor);
  const blue = Math.floor(((factor - 1) * 255 + Number("0x" + color.substr(1, 2))) / factor);
  return "#" + toHexaDecimal(blue) + toHexaDecimal(green) + toHexaDecimal(red);
}

/**
 * Installs a click listener on the video element that toggles play/pause.
 */
export function playOnClick() {
  const video = thymeAttributes.video;
  video.addEventListener("click", function () {
    if (video.paused) {
      video.play();
    }
    else {
      video.pause();
    }
  });
}

/**
 * Renders LaTeX in a given HTML element.
 */
export function renderLatex(element) {
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
}

/**
 * Converts time in seconds to a string of the form H:MM:SS.
 */
export function secondsToTime(seconds) {
  const date = new Date(null);
  date.setSeconds(seconds);
  return date.toISOString().substr(12, 7);
}

/**
 * Setups up the label on the right side of the seek bar which displays
 * the maximum time of the video.
 *
 * (In order to make this work, we have to wait for the video's metadata
 * to be loaded.)
 */
export function setUpMaxTime(maxTimeId) {
  const video = thymeAttributes.video;
  video.addEventListener("loadedmetadata", function () {
    const maxTime = document.getElementById(maxTimeId);
    maxTime.innerHTML = secondsToTime(video.duration);
    if (video.dataset.time) {
      const time = video.dataset.time;
      video.currentTime = time;
    }
  });
}

/**
 * Converts a JSON timestamp into a double value containing the time in seconds.
 */
export function timestampToSeconds(timestamp) {
  return 3600 * timestamp.hours + 60 * timestamp.minutes + timestamp.seconds + 0.001 * timestamp.milliseconds;
}

/**
 * Converts a given integer between 0 and 255 into a hexadecimal representation.
 */
export function toHexaDecimal(integer) {
  return integer.toString(16).padStart(2, "0");
}
