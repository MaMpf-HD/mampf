$(document).on('turbolinks:load', function() {
  /*
    VIDEO INITIALIZATION
   */
  // exit script if the current page has no thyme player
  const thymeContainer = document.getElementById('thyme-container');
  if (!thymeContainer) {
    return;
  }

  // background color
  document.body.style.backgroundColor = 'black';

  // initialize attributes
  const thyme = document.getElementById('thyme');
  const video = document.getElementById('video');
  thymeAttributes.video = video;
  thymeAttributes.mediumId = thyme.dataset.medium;
  thymeAttributes.markerBarId = 'markers';



  /*
    COMPONENTS
   */
  // annotation components
  const annotationFeatureActive = (document.getElementById('annotation-button') != null);
  thymeAttributes.annotationFeatureActive = annotationFeatureActive;
  if (annotationFeatureActive) {
    (new AnnotationButton('annotation-button')).add();
  }
  const annotationsToggle = new AnnotationsToggle('annotations-toggle');
  annotationsToggle.add();

  // regular components
  (new FullScreenButton('full-screen', thymeContainer)).add();
  (new MuteButton('mute')).add();
  (new NextChapterButton('next-chapter')).add();
  (new PlayButton('play-pause')).add();
  (new PreviousChapterButton('previous-chapter')).add();
  (new SpeedSelector('speed')).add();
  (new TimeButton('plus-ten', 10)).add();
  (new TimeButton('minus-ten', -10)).add();
  // initialize iaButton here to have the reference but call add() later
  // when we can define toHide (second argument which is set to null here)
  const iaButton = new IaButton('ia-active', null, [$(video), $('#video-controlBar')], '82%');
  (new VolumeBar('volume-bar')).add();
  seekBar = new SeekBar('seek-bar');
  seekBar.add();
  seekBar.addChapterTooltips();



  /*
    ANNOTATION FUNCTIONALITY
   */
  // annotation manager and area
  function colorFunc(annotation) {
    return annotation.color;
  }
  
  function onClose() {
    iaButton.minus();
  }
  
  function isValid(annotation) {
    return (!annotationsToggle.getValue() && !annotation.belongsToCurrentUser ? false : true);
  }
  
  const annotationArea = new AnnotationArea(true, colorFunc, onClose, isValid);
  thymeAttributes.annotationArea = annotationArea;
  
  function strokeColorFunc(annotation) {
    return 'black';
  }
  
  function sizeFunc(annotation) {
    return false;
  }
  
  function onClick(annotation) {
    iaButton.minus();
    annotationArea.update(annotation);
    annotationArea.show();
    $('#caption').hide();
  }
  
  function onUpdate() {
    /* update might change the annotation which is currently shown in the
       annotation area -> find the updated annotation in the annotation array
       and update the area. */
    if (annotationArea.annotation) {
      const id = annotationArea.annotation.id;
      annotationArea.update(AnnotationManager.find(id));
    }
  }
  
  const annotationManager = new AnnotationManager(colorFunc, strokeColorFunc, sizeFunc,
                                                  onClick, onUpdate, isValid);
  thymeAttributes.annotationManager = annotationManager;

  // Update annotations after deleting an annotation
  $(document).on('click', '#delete-button', function() {
    const annotationId = Number(document.getElementById('annotation_id').textContent);
    $.ajax(Routes.annotation_path(annotationId), {
      type: 'DELETE',
      dataType: 'json',
      data: {
        annotation_id: annotationId
      },
      success: function() {
        annotationManager.updateAnnotations();
        // close and open again = show normal IA
        iaButton.minus();
        iaButton.plus();
      }
    });
  });



  /*
    CHAPTERS & METADATA MANAGER
   */
  const iaBackButton = new IaBackButton('back-button', 'chapters');
  iaBackButton.add();
  const chapterManager  = new ChapterManager('chapters', iaBackButton);
  const metadataManager = new MetadataManager('metadata');
  thymeAttributes.chapterManager  = chapterManager;
  thymeAttributes.metadataManager = metadataManager;
  chapterManager.load();
  metadataManager.load();



  /*
    INTERACTIVE AREA
   */
  iaButton.toHide = [$('#caption'), annotationArea];
  iaButton.add();
  (new IaCloseButton('ia-close', iaButton)).add();



  /*
    RESIZE
   */
  // Manage large and small display
  function onEnlarge() {
    iaButton.plus();
  }
  
  const elements = [$('#caption'), $('#annotation-caption'), $('#video-controlBar')];
  const displayManager = new DisplayManager(elements, onEnlarge);

  // resizes the thyme container to the window dimensions, taking into account
  // whether the interactive area is displayed or hidden
  function resizeContainer() {
    const factor = $('#caption').is(':hidden') && $('#annotation-caption').is(':hidden') ? 1 : 1 / 0.82;
    resize.resizeContainer(thymeContainer, factor, 0);
    annotationManager.updateMarkers();
  };
  
  window.onresize = resizeContainer;
  video.onloadedmetadata = resizeContainer;



  /*
    KEYBOARD SHORTCUTS
   */
  thymeKeyShortcuts.addGeneralShortcuts();
  thymeKeyShortcuts.addPlayerShortcuts();



  /*
    MISC
   */
  const controlBarHider = new ControlBarHider('video-controlBar', 3000);
  controlBarHider.install();
  displayManager.updateControlBarType();
  thymeUtility.playOnClick();
  thymeUtility.setUpMaxTime('max-time');

  if (document.documentMode) {
    alert($('body').data('badbrowser'));
    displayManager.adaptToSmallDisplay();
    resizeContainer();
    return;
  }

});
