// set up everything: read out track data and initialize html elements
function setupHypervideoF() {
  const video = $('#video').get(0);
  if (video === null) {
    return;
  }
  document.body.style.backgroundColor = 'black';
};

$(document).on('turbolinks:load', function() {
  const thymeContainer = document.getElementById('thyme-feedback');
  // no need for thyme if no thyme container on the page
  if (thymeContainer === null) {
    return;
  }
  // Video
  const video = document.getElementById('video');
  thymeAttributes.video = video;
  const thyme = document.getElementById('thyme');
  // initialize medium id
  thymeAttributes.mediumId = thyme.dataset.medium;
  // initialize marker bar
  thymeAttributes.markerBarID = 'feedback-markers';

  // Buttons
  (new PlayButton('play-pause')).add();
  (new MuteButton('mute')).add();
  (new PlusTenButton('plus-ten')).add();
  (new MinusTenButton('minus-ten')).add();
  // Sliders
  (new VolumeBar('volume-bar')).add();
  seekBar = new SeekBar('seek-bar');
  seekBar.add();

  // heatmap
  const heatmap = new Heatmap(['presentation', 'content', 'note']);

  // below-area
  const toggleMistakeAnnotations = new AnnotationCategoryToggle(
    'toggle-mistake-annotations', 'mistake', heatmap);
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

  // reset faders
  video.currentTime = 0;
  video.volume = 1;

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
    const a = AnnotationManager.find(thymeAttributes.activeAnnotationId);
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

  // resizes the thyme container to the window dimensions
  function resizeContainer() {
    resize.resizeContainer(thymeContainer, 1);
    if (thymeAttributes.annotations === null) {
      annotationManager.updateAnnotations();
    } else {
      annotationManager.updateMarkers();
    }
  };

  // if videometadata have been loaded, set up video length
  video.addEventListener('loadedmetadata', function() {
    const maxTime = document.getElementById('max-time');
    maxTime.innerHTML = thymeUtility.secondsToTime(video.duration);
    if (video.dataset.time != null) {
      const time = video.dataset.time;
      video.currentTime = time;
    }
  });

  setupHypervideoF();
  window.onresize = resizeContainer;
  video.onloadedmetadata = resizeContainer;

  video.addEventListener('click', function() {
    if (video.paused === true) {
      video.play();
    } else {
      video.pause();
    }
    showControlBar();
  });

  // Add keyboard shortcuts from thyme/key.js
  thymeKeyShortcuts.addGeneralShortcuts();
  thymeKeyShortcuts.addFeedbackShortcuts();

});