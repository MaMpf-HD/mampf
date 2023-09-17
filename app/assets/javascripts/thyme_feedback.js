$(document).on('turbolinks:load', function() {

  /*
    VIDEO INITIALIZATION
   */
  // exit script if the current page has no thyme player
  const thymeContainer = document.getElementById('thyme-feedback');
  if (thymeContainer === null || $('#video').get(0) === null) {
    return;
  }

  // background color
  document.body.style.backgroundColor = 'black';

  // initialize attributes
  const video = document.getElementById('video');
  thymeAttributes.video = video;
  thymeAttributes.mediumId = document.getElementById('thyme').dataset.medium;
  thymeAttributes.markerBarId = 'feedback-markers';



  /*
    COMPONENTS
   */
  // Buttons
  (new MinusButton('minus-ten', 10)).add();
  (new MuteButton('mute')).add();
  (new PlayButton('play-pause')).add();
  (new PlusButton('plus-ten', 10)).add();
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
  function colorFunc(annotation) {
    return annotation.categoryColor();
  }
  function isValid(annotation) {
    for (let toggle of toggles) {
      if (annotation.category === toggle.category && toggle.getValue() === true) {
        return true;
      }
    }
    return false;
  }
  const annotationArea = new AnnotationArea(false, colorFunc, isValid);
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
  thymeUtility.setUpMaxTime('max-time');
  
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

});