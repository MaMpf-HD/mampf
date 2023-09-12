$(document).on('turbolinks:load', function() {

  /*
    VIDEO INITIALIZATION
   */
  // exit script if the current page is no thyme player
  const thymeContainer = document.getElementById('thyme-feedback');
  if (thymeContainer === null || $('#video').get(0) === null) {
    return;
  }
  document.body.style.backgroundColor = 'black';
  // initialize attributes
  const video = document.getElementById('video');
  thymeAttributes.video = video;
  thymeAttributes.mediumId = document.getElementById('thyme').dataset.medium;
  thymeAttributes.markerBarID = 'feedback-markers';



  /*
    PLAYER CONTENT
   */
  // Buttons
  (new PlayButton('play-pause')).add();
  (new MuteButton('mute')).add();
  (new PlusTenButton('plus-ten')).add();
  (new MinusTenButton('minus-ten')).add();
  // Sliders
  (new VolumeBar('volume-bar')).add();
  seekBar = new SeekBar('seek-bar');
  seekBar.add();

  // reset faders
  video.currentTime = 0;
  video.volume = 1;

  // heatmap
  const heatmap = new Heatmap('heatmap', ['presentation', 'content', 'note']);

  // below-area
  const toggleMistakeAnnotations = new AnnotationCategoryToggle(
    'toggle-mistake-annotations', 'mistake', null); // <- don't draw mistake annotations in the heatmap
  const togglePresentationAnnotations = new AnnotationCategoryToggle(
    'toggle-presentation-annotations', 'presentation', heatmap);
  const toggleContentAnnotations = new AnnotationCategoryToggle(
    'toggle-content-annotations', 'content', heatmap);
  const toggleNoteAnnotations = new AnnotationCategoryToggle(
    'toggle-note-annotations', 'note', heatmap);
  toggleMistakeAnnotations.add();
  togglePresentationAnnotations.add();
  toggleContentAnnotations.add();
  toggleNoteAnnotations.add();
  const toggles = [toggleMistakeAnnotations, togglePresentationAnnotations,
                   toggleContentAnnotations, toggleNoteAnnotations];

  

  /*
    ANNOTATION FUNCTIONALITY
   */
  // annotation manager and area
  function colorFunc(annotation) {
    return annotation.categoryColor();
  }
  const annotationArea = new AnnotationArea(false, colorFunc);
  thymeAttributes.annotationArea = annotationArea;
  function strokeColorFunc(annotation) {
    return annotation.category === 'mistake' ? 'darkred' : 'black';
  }
  function sizeFunc(annotation) {
    return annotation.category === 'mistake' ? true : false;
  }
  function onClick(annotation) {
    annotationArea.update(annotation);
  }
  function onUpdate() {
    const a = AnnotationManager.find(thymeAttributes.activeAnnotationID);
    annotationArea.update(a);
    heatmap.draw();
  }
  function isValid(annotation) {
    for (let toggle of toggles) {
      if (annotation.category === toggle.category && toggle.getValue() === true) {
        return true;
      }
    }
    return false;
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
  
  // resizes the thyme container to the window dimensions
  function resizeContainer() {
    resize.resizeContainer(thymeContainer, 1);
    if (thymeAttributes.annotations === null) {
      annotationManager.updateAnnotations();
    } else {
      annotationManager.updateMarkers();
    }
  };
  window.onresize = resizeContainer;
  video.onloadedmetadata = resizeContainer;

  // if videometadata have been loaded, set up video length
  video.addEventListener('loadedmetadata', function() {
    const maxTime = document.getElementById('max-time');
    maxTime.innerHTML = thymeUtility.secondsToTime(video.duration);
    if (video.dataset.time != null) {
      const time = video.dataset.time;
      video.currentTime = time;
    }
  });

});