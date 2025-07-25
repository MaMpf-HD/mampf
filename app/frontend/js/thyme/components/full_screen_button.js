import { Component } from "~/js/thyme/components/component";

export class FullScreenButton extends Component {
  constructor(element, container) {
    super(element);
    this.container = container;
  }

  add() {
    const element = this.element;
    const container = this.container;
    const button = this;

    // Event listener for the full-screen button
    // (unfortunately, lots of browser specific code).
    element.addEventListener("click", function () {
      if (element.dataset.status === "true") {
        if (document.exitFullscreen) {
          document.exitFullscreen();
        }
        else if (document.mozCancelFullScreen) {
          document.mozCancelFullScreen();
        }
        else if (document.webkitExitFullscreen) {
          document.webkitExitFullscreen();
        }
      }
      else {
        if (container.requestFullscreen) {
          container.requestFullscreen();
        }
        else if (container.mozRequestFullScreen) {
          container.mozRequestFullScreen();
        }
        else if (container.webkitRequestFullscreen) {
          container.webkitRequestFullscreen();
        }
      }
    });

    document.onfullscreenchange = function () {
      button.#fullscreenChange();
    };

    document.onwebkitfullscreenchange = function () {
      button.#fullscreenChange();
    };

    document.onmozfullscreenchange = function () {
      button.#fullscreenChange();
    };
  }

  #fullscreenChange() {
    if (document.fullscreenElement) {
      // User enters fullscreen mode
      this.element.innerHTML = "fullscreen_exit";
      this.element.dataset.status = "true";
      /* Set height to 100vh in fullscreen mode as it otherwise
         is too large. */
      $(thymeAttributes.video).css("height", "100vh");
    }
    else {
      // User exists fullscreen mode
      this.element.innerHTML = "fullscreen";
      this.element.dataset.status = "false";
      $(thymeAttributes.video).css("height", "100%");
    }
  }
}
