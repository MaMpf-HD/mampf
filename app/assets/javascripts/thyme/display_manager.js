/**
 * A DisplayManager helps to switch between the full thyme player and
 * the native HTML player shown on small devices.
 */
class DisplayManager {

  constructor(elements, onEnlarge) {
    /*
      elements = An array containing JQuery references on the HTML elements
                 that should be hidden, when the display is too small.

      onEnlarge = A reference to a function that is called when the display
                 changes from small to large. Use this for player specific behavior.
     */
    this.elements = elements;
    this.onEnlarge = onEnlarge;
  }



  // on small display, fall back to standard browser player
  adaptToSmallDisplay() {
    for (let e of this.elements) {
      e.hide();
    }
    thymeAttributes.video.style.width = '100%';
    thymeAttributes.video.controls = true;
  }

  // on large display, use anything thyme has to offer, disable native player
  adaptToLargeDisplay() {
    thymeAttributes.video.controls = false;
    for (let e of this.elements) {
      e.show();
    }
    this.onEnlarge();
  }

  // Check screen size and trigger the right method
  updateControlBarType() {
    const dm = this;

    if (window.matchMedia("screen and (max-width: " +
      thymeAttributes.hideControlBarThreshold.x + "px)").matches ||
      window.matchMedia("screen and (max-height: " +
        thymeAttributes.hideControlBarThreshold.y + "px)").matches) {
      dm.adaptToSmallDisplay();
    }

    if (window.matchMedia("screen and (max-device-width: " +
      thymeAttributes.hideControlBarThreshold.x + "px)").matches ||
      window.matchMedia("screen and (max-device-height: " +
        thymeAttributes.hideControlBarThreshold.y + "px)").matches) {
      dm.adaptToSmallDisplay();
    }

    // mediaQuery listener for very small screens
    const matchVerySmallX = window.matchMedia("screen and (max-width: " +
      thymeAttributes.hideControlBarThreshold.x + "px)");
    matchVerySmallX.addListener(function (result) {
      if (result.matches) {
        dm.adaptToSmallDisplay();
      }
    });
    const matchVerySmallY = window.matchMedia("screen and (max-height: " +
      thymeAttributes.hideControlBarThreshold.y + "px)");
    matchVerySmallY.addListener(function (result) {
      if (result.matches) {
        dm.adaptToSmallDisplay();
      }
    });

    const matchVerySmallDeviceX = window.matchMedia("screen and (max-device-width: " +
      thymeAttributes.hideControlBarThreshold.x + "px)");
    matchVerySmallDeviceX.addListener(function (result) {
      if (result.matches) {
        dm.adaptToSmallDisplay();
      }
    });
    const matchVerySmallDeviceY = window.matchMedia("screen and (max-device-height: " +
      thymeAttributes.hideControlBarThreshold.y + "px)");
    matchVerySmallDeviceY.addListener(function (result) {
      if (result.matches) {
        dm.adaptToSmallDisplay();
      }
    });

    // mediaQuery listener for normal screens
    let matchNormalX = window.matchMedia("screen and (min-width: " +
      (thymeAttributes.hideControlBarThreshold.x + 1) + "px)");
    matchNormalX.addListener(function (result) {
      let matchNormalY;
      matchNormalY = window.matchMedia("screen and (min-height: " +
        (thymeAttributes.hideControlBarThreshold.y + 1) + "px)");
      if (result.matches && matchNormalY.matches) {
        dm.adaptToLargeDisplay();
      }
    });
    const matchNormalY = window.matchMedia("screen and (min-height: " +
      (thymeAttributes.hideControlBarThreshold.y + 1) + "px)");
    matchNormalY.addListener(function (result) {
      matchNormalX = window.matchMedia("screen and (min-width: " +
        (thymeAttributes.hideControlBarThreshold.x + 1) + "px)");
      if (result.matches && matchNormalX.matches) {
        dm.adaptToLargeDisplay();
      }
    });

    let matchNormalDeviceX = window.matchMedia("screen and (min-device-width: " +
      (thymeAttributes.hideControlBarThreshold.x + 1) + "px)");
    let matchNormalDeviceY;
    matchNormalDeviceX.addListener(function (result) {
      matchNormalDeviceY = window.matchMedia("screen and (min-device-height: " +
        (thymeAttributes.hideControlBarThreshold.y + 1) + "px)");
      if (result.matches && matchNormalY.matches) {
        dm.adaptToLargeDisplay();
      }
    });
    matchNormalDeviceY = window.matchMedia("screen and (min-device-height: " +
      (thymeAttributes.hideControlBarThreshold.y + 1) + "px)");
    matchNormalDeviceY.addListener(function (result) {
      matchNormalDeviceX = window.matchMedia("screen and (min-device-width: " +
        (thymeAttributes.hideControlBarThreshold.x + 1) + "px)");
      if (result.matches && matchNormalX.matches) {
        dm.adaptToLargeDisplay();
      }
    });
  }

};
