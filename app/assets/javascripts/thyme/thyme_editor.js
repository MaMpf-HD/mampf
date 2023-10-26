$(document).on('turbolinks:load', function() {
  /*
    VIDEO INITIALIZATION
   */
  // exit script if the current page has no thyme player
  const thymeEdit = document.getElementById('thyme-edit');
  if (!thymeEdit) {
    return;
  }
  // initialize attributes
  const video = document.getElementById('video-edit');
  const mediumId = thymeEdit.dataset.medium;
  thymeAttributes.video = video;
  thymeAttributes.mediumId = thymeEdit.dataset.medium;



  /*
    COMPONENTS
   */
  (new PlayButton('play-pause')).add();
  (new MuteButton('mute')).add();

  (new TimeButton('plus-ten', 10)).add();
  (new TimeButton('plus-five', 5)).add();
  (new TimeButton('plus-one', 1)).add();
  (new TimeButton('minus-ten', -10)).add();
  (new TimeButton('minus-five', -5)).add();
  (new TimeButton('minus-one', -1)).add();

  (new SeekBar('seek-bar')).add();
  (new VolumeBar('volume-bar')).add();

  (new AddItemButton('add-item')).add();
  (new AddReferenceButton('add-reference')).add();
  (new AddScreenshotButton('add-screenshot', 'snapshot')).add();

  thymeUtility.setUpMaxTime('max-time');

});
