/**
 * A DisplayManager helps to switch between the full thyme player and
 * the native HTML player shown on small devices.
 */
class DisplayManager {

  constructor(elements, func) {
    /*
      elements = An array containing JQuery references on the HTML elements
                 that should be hidden, when the display is too small.

          func = A reference on a function that is called when the display
                 changes from small to large. Use this for player specific behaviour.
     */
    this.elements = elements;
    this.func = func;
  }



  // on small display, fall back to standard browser player
  smallDisplay() {
    for (let e of this.elements) {
      e.hide();
    }
    thymeAttributes.video.style.width = '100';
    thymeAttributes.video.controls = true;
  }

  // on large display, use anything thyme has to offer, disable native player
  largeDisplay() {
    thymeAttributes.video.controls = false;
    for (let e of this.elements) {
      e.show();
    }
    this.func();
  }

  // Check screen size and trigger the right method
  updateControlBarType() {
    const dm = this;

    if (window.matchMedia("screen and (max-width: " +
        thymeAttributes.hideControlBarThreshold.x + "px)").matches ||
        window.matchMedia("screen and (max-height: " +
        thymeAttributes.hideControlBarThreshold.y + "px)").matches) {
      dm.smallDisplay();
    }

    if (window.matchMedia("screen and (max-device-width: " +
        thymeAttributes.hideControlBarThreshold.x + "px)").matches ||
        window.matchMedia("screen and (max-device-height: " +
        thymeAttributes.hideControlBarThreshold.y + "px)").matches) {
      dm.smallDisplay();
    }

    // mediaQuery listener for very small screens
    const match_verysmall_x = window.matchMedia("screen and (max-width: " +
      thymeAttributes.hideControlBarThreshold.x + "px)");
    match_verysmall_x.addListener(function(result) {
      if (result.matches) {
        dm.smallDisplay();
      }
    });
    const match_verysmall_y = window.matchMedia("screen and (max-height: " +
      thymeAttributes.hideControlBarThreshold.y + "px)");
    match_verysmall_y.addListener(function(result) {
      if (result.matches) {
        dm.smallDisplay();
      }
    });

    const match_verysmalldevice_x = window.matchMedia("screen and (max-device-width: " +
      thymeAttributes.hideControlBarThreshold.x + "px)");
    match_verysmalldevice_x.addListener(function(result) {
      if (result.matches) {
        dm.smallDisplay();
      }
    });
    const match_verysmalldevice_y = window.matchMedia("screen and (max-device-height: " +
      thymeAttributes.hideControlBarThreshold.y + "px)");
    match_verysmalldevice_y.addListener(function(result) {
      if (result.matches) {
        dm.smallDisplay();
      }
    });

    // mediaQuery listener for normal screens
    let match_normal_x = window.matchMedia("screen and (min-width: " +
      (thymeAttributes.hideControlBarThreshold.x + 1) + "px)");
    match_normal_x.addListener(function(result) {
      let match_normal_y;
      match_normal_y = window.matchMedia("screen and (min-height: " +
        (thymeAttributes.hideControlBarThreshold.y + 1) + "px)");
      if (result.matches && match_normal_y.matches) {
        dm.largeDisplay();
      }
    });
    const match_normal_y = window.matchMedia("screen and (min-height: " +
      (thymeAttributes.hideControlBarThreshold.y + 1) + "px)");
    match_normal_y.addListener(function(result) {
      match_normal_x = window.matchMedia("screen and (min-width: " +
        (thymeAttributes.hideControlBarThreshold.x + 1) + "px)");
      if (result.matches && match_normal_x.matches) {
        dm.largeDisplay();
      }
    });

    let match_normaldevice_x = window.matchMedia("screen and (min-device-width: " +
      (thymeAttributes.hideControlBarThreshold.x + 1) + "px)");
    let match_normaldevice_y;
    match_normaldevice_x.addListener(function(result) {
      match_normaldevice_y = window.matchMedia("screen and (min-device-height: " +
        (thymeAttributes.hideControlBarThreshold.y + 1) + "px)");
      if (result.matches && match_normal_y.matches) {
        dm.largeDisplay();
      }
    });
    match_normaldevice_y = window.matchMedia("screen and (min-device-height: " +
      (thymeAttributes.hideControlBarThreshold.y + 1) + "px)");
    match_normaldevice_y.addListener(function(result) {
      match_normaldevice_x = window.matchMedia("screen and (min-device-width: " +
        (thymeAttributes.hideControlBarThreshold.x + 1) + "px)");
      if (result.matches && match_normal_x.matches) {
        dm.largeDisplay();
      }
    });
  }

};