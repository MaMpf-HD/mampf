/**
 * This class contains the functionality for (auto-)hiding the control bar.
 */
class ControlBarHider {

  /*
    controlBarId = The ID of the control bar.
           delay = The delay after which the control bar is automatically hidden.
   */
  constructor(controlBarId, delay) {
    this.controlBarId = controlBarId;
    this.delay = delay;
    this.hideBlocker = false; // helper attribute
  }

  /*
    Installs the control bar hider, i.e. after calling this method it will
    start working.
   */
  install() {
    const controlBarHider = this;
    const controlBar = document.getElementById(this.controlBarId);
    const video = thymeAttributes.video;

    // show control bar when mouse is moved, etc.
    function show() {
      controlBarHider.showControlBar(); // <- need this extra function for reference
    }
    /* NOTE: Why do we need the mouseover listener? To trigger it, the mouse
       has to be moved, i.e. the second event listener is triggered. */
    video.addEventListener('mouseover', show);
    video.addEventListener('mousemove', show);
    video.addEventListener('touchstart', show);
    video.addEventListener('click', show);

    // block hiding if curser is over the control bar
    controlBar.addEventListener('mouseover', function() {
      controlBarHider.hideBlocker = true;
    });
    controlBar.addEventListener('mouseleave', function() {
      controlBarHider.hideBlocker = false;
    });

    // auto hide control bar
    let t = void 0;
    function resetTimer() {
      clearTimeout(t);
      t = setTimeout(function() {
        if (controlBarHider.hideBlocker === true) {
          return;
        }
        controlBarHider.hideControlBar();
      }, controlBarHider.delay);
    };
    window.onload = resetTimer;
    window.onmousemove = resetTimer;
    window.onmousedown = resetTimer;
    window.ontouchstart = resetTimer;
    window.onclick = resetTimer;
  }



  /*
    AUXILIARY METHODS
   */
  showControlBar() {
    $('#' + this.controlBarId).css('visibility', 'visible');
    $(thymeAttributes.video).css('cursor', '');
  };

  hideControlBar() {
    $('#' + this.controlBarId).css('visibility', 'hidden');
    $(thymeAttributes.video).css('cursor', 'none');
  };

}
