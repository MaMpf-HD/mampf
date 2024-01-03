class TimeButton extends Component {
  /*
    time = The time to add in seconds.
   */
  constructor(element, time) {
    super(element);
    this.time = time;
  }

  add() {
    const video = thymeAttributes.video;
    const time = this.time;

    this.element.addEventListener("click", function () {
      if (time >= 0) {
        video.currentTime = Math.min(video.currentTime + time, video.duration);
      }
      else {
        video.currentTime = Math.max(video.currentTime + time, 0);
      }
    });
  }
}
