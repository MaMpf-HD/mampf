class SpeedSelector extends Component {

  constructor(element) {
    super(element);
  }

  /* This method should add the button functionality to the given player.
     Override it in the given subclass! */
  add() {
    const video = thymeAttributes.video;
    const element = this.element;

    element.addEventListener('click', function() {
      if (video.preservesPitch) {
        video.preservesPitch = true;
      } else if (video.mozPreservesPitch) {
        video.mozPreservesPitch = true;
      } else if (video.webkitPreservesPitch) {
        video.webkitPreservesPitch = true;
      }
      video.playbackRate = this.options[this.selectedIndex].value;
    });
  }

}
