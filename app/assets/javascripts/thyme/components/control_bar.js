/**
 * This class contains the functionality for (auto-)hiding the control bar.
 */
class ControlBar extends Component {

  static AUTO_HIDE_SECONDS = 3000; // The delay (in millis) after which the control bar auto-hides.

  /*
    autoHide = If true, the control bar hides itself after 3 seconds.
   */
  constructor(element, autoHide) {
    super(element);
    this.autoHide = autoHide;
    this.hideBlocker = false; // helper attribute
  }

  add() {
    const controlBar = this;
    const id = this.element.id;
    const video = thymeAttributes.video;

    // show control bar when mouse is moved, etc.
    function show() {
      controlBar.showControlBar(); // <- need this extra function for reference
    }
    /* NOTE: Why do we need the mouseover listener? To trigger it, the mouse
       has to be moved, i.e. the second event listener is triggered. */
    video.addEventListener('mouseover', show);
    video.addEventListener('mousemove', show);
    video.addEventListener('touchstart', show);
    video.addEventListener('click', show);

    // block hiding if curser is over the control bar
    this.element.addEventListener('mouseover', function() {
      controlBar.hideBlocker = true;
    });
    this.element.addEventListener('mouseleave', function() {
      controlBar.hideBlocker = false;
    });

    // auto hide control bar
    if (this.autoHide === true) {
      let t = void 0;
      function resetTimer() {
        clearTimeout(t);
        t = setTimeout(function() {
          if (controlBar.hideBlocker === true) {
            return;
          }
          controlBar.hideControlBar();
        }, ControlBar.AUTO_HIDE_SECONDS);
      };
      window.onload = resetTimer;
      window.onmousemove = resetTimer;
      window.onmousedown = resetTimer;
      window.ontouchstart = resetTimer;
      window.onclick = resetTimer;
    }
  }



  /*
    AUXILIARY METHODS
   */
  showControlBar() {
    $('#' + this.element.id).css('visibility', 'visible');
    $('#' + thymeAttributes.video.id).css('cursor', '');
  };

  hideControlBar() {
    $('#' + this.element.id).css('visibility', 'hidden');
    $('#' + thymeAttributes.video.id).css('cursor', 'none');
  };

}
