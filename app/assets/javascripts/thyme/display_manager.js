/**
 * A DisplayManager helps to switch between the full thyme player and
 * the native HTML player shown on small devices.
 */
// eslint-disable-next-line no-unused-vars
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
    thymeAttributes.video.style.width = "100%";
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
    const manager = this;

    const matchSmallMediaQuery = window.matchMedia(`
      screen and (
        (max-width: ${thymeAttributes.hideControlBarThreshold.x}px)
        or (max-height: ${thymeAttributes.hideControlBarThreshold.y}px)
      )
    `);

    function handleSizeChange(event) {
      if (event.matches) {
        manager.adaptToSmallDisplay();
      }
      else {
        manager.adaptToLargeDisplay();
      }
    }

    matchSmallMediaQuery.addListener(handleSizeChange);
    handleSizeChange(matchSmallMediaQuery); // initial call
  }
}
