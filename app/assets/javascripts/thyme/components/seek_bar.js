// eslint-disable-next-line no-unused-vars
class SeekBar extends Component {
  constructor(element) {
    super(element);
    thymeAttributes.seekBar = this; // save a reference for this seek bar
  }

  add() {
    const video = thymeAttributes.video;
    const element = this.element;

    // Event listeners for the seek bar
    element.addEventListener("input", function () {
      const time = video.duration * element.value / 100;
      video.currentTime = time;
    });

    // if videomedtadata have been loaded, set up seek bar
    video.addEventListener("loadedmetadata", function () {
      if (video.dataset.time) {
        element.value = video.currentTime / video.duration * 100;
      }
      else {
        element.value = 0;
      }
    });

    // Update the seek bar as the video plays.
    // Uses a gradient for seekbar video time visualization.
    video.addEventListener("timeupdate", function () {
      const value = 100 / video.duration * video.currentTime;
      element.value = value;
      element.style.backgroundImage = "linear-gradient(to right,"
      + " #2497E3, #2497E3 "
      + value
      + "%, #ffffff "
      + value
      + "%, #ffffff)";
      const currentTime = document.getElementById("current-time");
      currentTime.innerHTML = thymeUtility.secondsToTime(video.currentTime);
    });

    // Pause the video when the seek handle is being dragged
    element.addEventListener("mousedown", function () {
      video.dataset.paused = video.paused;
      video.pause();
    });

    // Play the video when the seek handle is dropped
    element.addEventListener("mouseup", function () {
      if (video.dataset.paused !== "true") {
        video.play();
      }
    });
  }

  /*
    If mouse is moved over seek bar, display tooltip with current chapter
    (only use this if the given thyme player provides chapters!).
  */
  addChapterTooltips() {
    const element = this.element;

    element.addEventListener("mousemove", function (evt) {
      const previous = thymeAttributes.chapterManager.previousChapterStart();
      const info = $("#c-" + $.escapeSelector(previous)).text().split(":")[0];
      element.setAttribute("title", info);
    });
  }
}
