import { AnnotationArea } from "./annotations/annotation_area";
import { AnnotationManager } from "./annotations/annotation_manager";
import { Category } from "./annotations/category";
import { openAnnotationIfSpecifiedInUrl } from "./annotations/url_annotation_opener";
import { AnnotationCategoryToggle } from "./components/annotation_category_toggle";
import { MuteButton } from "./components/mute_button";
import { PlayButton } from "./components/play_button";
import { SeekBar } from "./components/seek_bar";
import { TimeButton } from "./components/time_button";
import { VolumeBar } from "./components/volume_bar";
import { Heatmap } from "./heatmap";
import { addFeedbackShortcuts, addGeneralShortcuts } from "./key_shortcuts";
import { resizeThymeContainer } from "./resizer";
import { playOnClick, setUpMaxTime } from "./utility";

$(document).on("turbo:load", function () {
  /*
    VIDEO INITIALIZATION
   */
  // exit script if the current page has no thyme player
  const thymeContainer = document.getElementById("thyme-feedback-container");
  if (!thymeContainer) {
    return;
  }

  // background color
  document.body.style.backgroundColor = "black";

  // initialize attributes
  const video = document.getElementById("video");
  thymeAttributes.video = video;
  thymeAttributes.mediumId = document.getElementById("thyme-feedback").dataset.medium;
  thymeAttributes.markerBarId = "feedback-markers";

  /*
    COMPONENTS
   */
  // Buttons
  (new MuteButton("mute")).add();
  (new PlayButton("play-pause")).add();
  (new TimeButton("plus-ten", 10)).add();
  (new TimeButton("minus-ten", -10)).add();
  // Sliders
  (new VolumeBar("volume-bar")).add();
  (new SeekBar("seek-bar")).add();

  // heatmap
  const heatmap = new Heatmap("heatmap");

  // category toggles
  const allCategories = Category.all();
  const annotationCategoryToggles = new Array(allCategories.length);
  let category;

  for (let i = 0; i < allCategories.length; i++) {
    category = allCategories[i];
    annotationCategoryToggles[i] = new AnnotationCategoryToggle(category, heatmap);
    annotationCategoryToggles[i].add();
  }

  /*
    ANNOTATION FUNCTIONALITY
   */
  function colorFunc(annotation) {
    return annotation.category.color;
  }

  function isValid(annotation) {
    for (let toggle of annotationCategoryToggles) {
      if (annotation.category === toggle.category && toggle.isChecked()) {
        return true;
      }
    }
    return false;
  }

  const annotationArea = new AnnotationArea(false, colorFunc, null, isValid);
  thymeAttributes.annotationArea = annotationArea;

  function strokeColorFunc(annotation) {
    return annotation.category === Category.MISTAKE ? "darkred" : "black";
  }

  function sizeFunc(annotation) {
    return annotation.category === Category.MISTAKE;
  }

  function onClick(annotation) {
    annotationArea.update(annotation);
  }

  function onUpdate() {
    heatmap.draw();
  }

  const annotationManager = new AnnotationManager(colorFunc, strokeColorFunc, sizeFunc,
    onClick, onUpdate, isValid);
  thymeAttributes.annotationManager = annotationManager;
  thymeAttributes.annotationFeatureActive = true;

  // update annotations manually once as initialization
  annotationManager.updateAnnotations(() => {
    openAnnotationIfSpecifiedInUrl();
  });

  /*
    KEYBOARD SHORTCUTS
   */
  addGeneralShortcuts();
  addFeedbackShortcuts();

  /*
    MISC
   */
  playOnClick();
  setUpMaxTime("max-time");

  // resizes the thyme container to the window dimensions
  function resizeContainer() {
    resizeThymeContainer(thymeContainer, 1 / 0.82, 0);
    annotationManager.updateMarkers();
  }

  window.onresize = resizeContainer;
  video.onloadedmetadata = resizeContainer;

  $("#video").width("82%");
  resizeContainer();
});
