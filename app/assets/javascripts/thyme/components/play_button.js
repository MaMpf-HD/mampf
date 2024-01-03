class PlayButton extends Component {
  add() {
    const video = thymeAttributes.video;
    const element = this.element;

    element.addEventListener("click", function () {
      if (video.paused) {
        video.play();
      }
      else {
        video.pause();
      }
    });

    video.onplay = function () {
      element.innerHTML = "pause";
    };

    video.onpause = function () {
      element.innerHTML = "play_arrow";
    };
  }
}
