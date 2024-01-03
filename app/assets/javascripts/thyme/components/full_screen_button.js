// eslint-disable-next-line no-unused-vars
class FullScreenButton extends Component {
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
      this.element.innerHTML = "fullscreen_exit";
      this.element.dataset.status = "true";
      /* Set height to 100vh in fullscreen mode as it otherwise
         is too large. */
      $(thymeAttributes.video).css("height", "100vh");
    }
    else {
      this.element.innerHTML = "fullscreen";
      this.element.dataset.status = "false";
      $(thymeAttributes.video).css("height", "100%");
      /* brute force patch: apparently, after exiting fullscreen mode,
         window.onresize is triggered twice(!), the second time with incorrect
         window height data, which results in a video area not quite filling
         the whole window. The next line resizes the container again. */
      setTimeout(resize.resizeContainer($(this.container), 1, 0), 20);
    }
  }
}
