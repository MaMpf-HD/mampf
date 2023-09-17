// convert given dataURL to Blob, used for converting screenshot canvas to png
function dataURLtoBlob(dataURL) {
  // Decode the dataURL
  const binary = atob(dataURL.split(',')[1]);
  // Create 8-bit unsigned array
  let array = [];
  for (let i = 0; i < binary.length; i++) {
    array.push(binary.charCodeAt(i));
  }
  // Return our Blob object
  return new Blob([new Uint8Array(array)], {
    type: 'image/png'
  });
};

$(document).on('turbolinks:load', function() {
  /*
    VIDEO INITIALIZATION
   */
  // exit script if the current page has no thyme player
  const thymeEdit = document.getElementById('thyme-edit');
  if (thymeEdit === null || $('#video').get(0) === null) {
    return;
  }
  // initialize attributes
  const video = document.getElementById('video-edit');
  thymeAttributes.video = video;
  thymeAttributes.mediumId = thymeEdit.dataset.medium;



  /*
    COMPONENTS
   */
  (new PlayButton('play-pause')).add();
  (new MuteButton('mute')).add();

  (new PlusButton('plus-ten', 10)).add();
  (new PlusButton('plus-five', 5)).add();
  (new PlusButton('plus-one', 1)).add();
  (new MinusButton('minus-ten', 10)).add();
  (new MinusButton('minus-five', 5)).add();
  (new MinusButton('minus-one', 1)).add();

  (new SeekBar('seek-bar')).add();



  const addItemButton = document.getElementById('add-item');
  const addReferenceButton = document.getElementById('add-reference');
  const addScreenshotButton = document.getElementById('add-screenshot');
  // Sliders
  const volumeBar = document.getElementById('volume-bar');
  // Times
  const currentTime = document.getElementById('current-time');
  const maxTime = document.getElementById('max-time');
  // Screenshot Canvas
  const canvas = document.getElementById('snapshot');




  // Event listener for addItem button
  addItemButton.addEventListener('click', function() {
    video.pause();
    // round time down to three decimal digits
    const time = video.currentTime;
    const intTime = Math.floor(time);
    const roundTime = intTime + Math.floor((time - intTime) * 1000) / 1000;
    video.currentTime = roundTime;
    $.ajax(Routes.add_item_path(mediumId), {
      type: 'GET',
      dataType: 'script',
      data: {
        time: video.currentTime
      }
    });
  });

  // Event listener for addItem button
  addReferenceButton.addEventListener('click', function() {
    video.pause();
    // round time down to three decimal digits
    const time = video.currentTime;
    const intTime = Math.floor(time);
    const roundTime = intTime + Math.floor((time - intTime) * 1000) / 1000;
    video.currentTime = roundTime;
    $.ajax(Routes.add_reference_path(mediumId), {
      type: 'GET',
      dataType: 'script',
      data: {
        time: video.currentTime
      }
    });
  });

  // Event listener for add screenshot button
  addScreenshotButton.addEventListener('click', function() {
    video.pause();
    // extract video screenshot from canvas
    const context = canvas.getContext('2d');
    context.drawImage(video, 0, 0, canvas.width, canvas.height);
    const base64image = canvas.toDataURL('image/png');
    // Get our file
    const file = dataURLtoBlob(base64image);
    // Create new form data
    const fd = new FormData;
    // Append our Canvas image file to the form data
    fd.append('image', file);
    // And send it
    $.ajax(Routes.add_screenshot_path(mediumId), {
      type: 'POST',
      data: fd,
      processData: false,
      contentType: false
    });
  });

  /* after video metadata have been loaded, set up video length, volume bar and
     seek bar */
  video.addEventListener('loadedmetadata', function() {
    maxTime.innerHTML = thymeUtility.secondsToTime(video.duration);
    volumeBar.value = video.volume;
    volumeBar.style.backgroundImage = 'linear-gradient(to right,' + ' #2497E3, #2497E3 ' + video.volume * 100 + '%, #ffffff ' + video.volume * 100 + '%, #ffffff)';
    canvas.width = Math.floor($(video).width());
    canvas.height = Math.floor($(video).height());
  });

  // Update the seek bar as the video plays
  video.addEventListener('timeupdate', function() {
    const value = 100 / video.duration * video.currentTime;
    currentTime.innerHTML = thymeUtility.secondsToTime(video.currentTime);
  });

  // Event listener for the volume bar
  volumeBar.addEventListener('change', function() {
    const value = volumeBar.value;
    video.volume = value;
  });

  video.addEventListener('volumechange', function() {
    const value = video.volume;
    volumeBar.value = value;
    volumeBar.style.backgroundImage = 'linear-gradient(to right,' + ' #2497E3, #2497E3 ' + value * 100 + '%, #ffffff ' + value * 100 + '%, #ffffff)';
  });
});
