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
    if (window.matchMedia("screen and (max-width: " +
      thymeAttributes.hideControlBarThreshold.x + "px)").matches ||
      window.matchMedia("screen and (max-height: " +
        thymeAttributes.hideControlBarThreshold.y + "px)").matches) {
      this.adaptToSmallDisplay();
    }

    if (window.matchMedia("screen and (max-device-width: " +
      thymeAttributes.hideControlBarThreshold.x + "px)").matches ||
      window.matchMedia("screen and (max-device-height: " +
        thymeAttributes.hideControlBarThreshold.y + "px)").matches) {
      this.adaptToSmallDisplay();
    }

    // mediaQuery listener for very small screens
    const matchVerysmallX = window.matchMedia("screen and (max-width: " +
      thymeAttributes.hideControlBarThreshold.x + "px)");
    matchVerysmallX.addListener(function (result) {
      if (result.matches) {
        this.adaptToSmallDisplay();
      }
    });
    const matchVerysmallY = window.matchMedia("screen and (max-height: " +
      thymeAttributes.hideControlBarThreshold.y + "px)");
    matchVerysmallY.addListener(function (result) {
      if (result.matches) {
        this.adaptToSmallDisplay();
      }
    });

    const matchVerysmalldeviceX = window.matchMedia("screen and (max-device-width: " +
      thymeAttributes.hideControlBarThreshold.x + "px)");
    matchVerysmalldeviceX.addListener(function (result) {
      if (result.matches) {
        this.adaptToSmallDisplay();
      }
    });
    const matchVerysmalldeviceY = window.matchMedia("screen and (max-device-height: " +
      thymeAttributes.hideControlBarThreshold.y + "px)");
    matchVerysmalldeviceY.addListener(function (result) {
      if (result.matches) {
        this.adaptToSmallDisplay();
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
        this.adaptToLargeDisplay();
      }
    });
    const matchNormalY = window.matchMedia("screen and (min-height: " +
      (thymeAttributes.hideControlBarThreshold.y + 1) + "px)");
    matchNormalY.addListener(function (result) {
      matchNormalX = window.matchMedia("screen and (min-width: " +
        (thymeAttributes.hideControlBarThreshold.x + 1) + "px)");
      if (result.matches && matchNormalX.matches) {
        this.adaptToLargeDisplay();
      }
    });

    let matchNormaldeviceX = window.matchMedia("screen and (min-device-width: " +
      (thymeAttributes.hideControlBarThreshold.x + 1) + "px)");
    let matchNormaldeviceY;
    matchNormaldeviceX.addListener(function (result) {
      matchNormaldeviceY = window.matchMedia("screen and (min-device-height: " +
        (thymeAttributes.hideControlBarThreshold.y + 1) + "px)");
      if (result.matches && matchNormalY.matches) {
        this.adaptToLargeDisplay();
      }
    });
    matchNormaldeviceY = window.matchMedia("screen and (min-device-height: " +
      (thymeAttributes.hideControlBarThreshold.y + 1) + "px)");
    matchNormaldeviceY.addListener(function (result) {
      matchNormaldeviceX = window.matchMedia("screen and (min-device-width: " +
        (thymeAttributes.hideControlBarThreshold.x + 1) + "px)");
      if (result.matches && matchNormalX.matches) {
        this.adaptToLargeDisplay();
      }
    });
  }

};
