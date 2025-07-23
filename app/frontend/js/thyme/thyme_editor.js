import { AddItemButton } from "./components/add_item_button";
import { AddReferenceButton } from "./components/add_reference_button";
import { AddScreenshotButton } from "./components/add_screenshot_button";
import { MuteButton } from "./components/mute_button";
import { PlayButton } from "./components/play_button";
import { SeekBar } from "./components/seek_bar";
import { TimeButton } from "./components/time_button";
import { VolumeBar } from "./components/volume_bar";
import { setUpMaxTime } from "./utility";

$(document).ready(function () {
  /*
    VIDEO INITIALIZATION
   */
  // exit script if the current page has no thyme player
  const thymeEdit = document.getElementById("thyme-edit");
  if (!thymeEdit) {
    return;
  }
  // initialize attributes
  const video = document.getElementById("video-edit");
  thymeAttributes.video = video;
  thymeAttributes.mediumId = thymeEdit.dataset.medium;

  const canvasId = "snapshot";

  // Adjust the width of the canvas according to the video
  // such that screenshot generation is performed with the same ratio.
  video.addEventListener("loadedmetadata", () => {
    this.canvas = document.getElementById(canvasId);
    this.canvas.width = Math.floor($(video).width());
    this.canvas.height = Math.floor($(video).height());
  });

  /*
    COMPONENTS
   */
  (new PlayButton("play-pause")).add();
  (new MuteButton("mute")).add();

  (new TimeButton("plus-ten", 10)).add();
  (new TimeButton("plus-five", 5)).add();
  (new TimeButton("plus-one", 1)).add();
  (new TimeButton("minus-ten", -10)).add();
  (new TimeButton("minus-five", -5)).add();
  (new TimeButton("minus-one", -1)).add();

  (new SeekBar("seek-bar")).add();
  (new VolumeBar("volume-bar")).add();

  (new AddItemButton("add-item")).add();
  (new AddReferenceButton("add-reference")).add();
  (new AddScreenshotButton("add-screenshot", canvasId)).add();

  setUpMaxTime("max-time");
});
