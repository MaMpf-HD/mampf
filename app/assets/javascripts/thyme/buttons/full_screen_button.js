class FullScreenButton extends Button  {
  constructor(container) {
    super('full-screen');
    this.container = container;
  }

  add() {
    const video = this.video;
    const element = this.element;
    const container = this.container;

    // Event listener for the full-screen button
    // (unfortunately, lots of browser specific code).
    element.addEventListener('click', function() {
      if (element.dataset.status === 'true') {
        if (document.exitFullscreen) {
          document.exitFullscreen();
        } else if (document.mozCancelFullScreen) {
          document.mozCancelFullScreen();
        } else if (document.webkitExitFullscreen) {
          document.webkitExitFullscreen();
        }
      } else {
        if (container.requestFullscreen) {
          container.requestFullscreen();
        } else if (container.mozRequestFullScreen) {
          container.mozRequestFullScreen();
        } else if (container.webkitRequestFullscreen) {
          container.webkitRequestFullscreen();
        }
      }
    });

    document.onfullscreenchange = function() {
      if (document.fullscreenElement !== null) {
        element.innerHTML = 'fullscreen_exit';
        element.dataset.status = 'true';
      } else {
        element.innerHTML = 'fullscreen';
        element.dataset.status = 'false';
        /* brute force patch: apparently, after exiting fullscreen mode,
          window.onresize is triggered twice(!), the second time with incorrect
          window height data, which results in a video area not quite filling
          the whole window. The next line resizes the container again. */
        setTimeout(resize.resizeContainer($('#' + container.id), 20));
      }
    };

    document.onwebkitfullscreenchange = function() {
      if (document.webkitFullscreenElement !== null) {
        element.innerHTML = 'fullscreen_exit';
        element.dataset.status = 'true';
      } else {
        element.innerHTML = 'fullscreen';
        element.dataset.status = 'false';
        setTimeout(resize.resizeContainer($('#' + container.id), 20));
      }
    };

    document.onmozfullscreenchange = function() {
      if (document.mozFullScreenElement !== null) {
        element.innerHTML = 'fullscreen_exit';
        element.dataset.status = 'true';
      } else {
        element.innerHTML = 'fullscreen';
        element.dataset.status = 'false';
        setTimeout(resize.resizeContainer($('#' + container.id), 20));
      }
    };
  }
}
