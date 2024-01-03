$(document).on("turbolinks:load", function () {
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
  seekBar = new SeekBar("seek-bar");
  seekBar.add();

  // heatmap
  const heatmap = new Heatmap("heatmap");

  // below-area
  const allCategories = Category.all();
  const annotationCategoryToggles = new Array(allCategories.length);
  let category;

  for (let i = 0; i < allCategories.length; i++) {
    category = allCategories[i];
    annotationCategoryToggles[i] = new AnnotationCategoryToggle(
      "toggle-" + category.name + "-annotations", category, heatmap,
    );
    if (category === Category.MISTAKE) {
      // exclude mistake annotations from heatmap
      annotationCategoryToggles[i].heatmap = null;
    }
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
      if (annotation.category === toggle.category && toggle.getValue()) {
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

  /*
    KEYBOARD SHORTCUTS
   */
  thymeKeyShortcuts.addGeneralShortcuts();
  thymeKeyShortcuts.addFeedbackShortcuts();

  /*
    MISC
   */
  thymeUtility.playOnClick();
  thymeUtility.setUpMaxTime("max-time");

  // resizes the thyme container to the window dimensions
  function resizeContainer() {
    resize.resizeContainer(thymeContainer, 1.22, 70);
    annotationManager.updateMarkers();
  }

  window.onresize = resizeContainer;
  video.onloadedmetadata = resizeContainer;
});
