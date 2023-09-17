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
  const thymeEdit = document.getElementById('thyme-edit');
  if (thymeEdit == null) {
    return;
  }
  const mediumId = thymeEdit.dataset.medium;
  // Video
  const video = document.getElementById('video-edit');
  // Buttons
  const playButton = document.getElementById('play-pause');
  const muteButton = document.getElementById('mute');
  const plusTenButton = document.getElementById('plus-ten');
  const plusFiveButton = document.getElementById('plus-five');
  const plusOneButton = document.getElementById('plus-one');
  const minusOneButton = document.getElementById('minus-one');
  const minusFiveButton = document.getElementById('minus-five');
  const minusTenButton = document.getElementById('minus-ten');
  const addItemButton = document.getElementById('add-item');
  const addReferenceButton = document.getElementById('add-reference');
  const addScreenshotButton = document.getElementById('add-screenshot');
  // Sliders
  const seekBar = document.getElementById('seek-bar');
  const volumeBar = document.getElementById('volume-bar');
  // Times
  const currentTime = document.getElementById('current-time');
  const maxTime = document.getElementById('max-time');
  // Screenshot Canvas
  const canvas = document.getElementById('snapshot');

  // Event listener for the play/pause button
  playButton.addEventListener('click', function() {
    if (video.paused == true) {
      video.play();
    } else {
      video.pause();
    }
  });

  video.onplay = function() {
    playButton.innerHTML = 'pause';
  };

  video.onpause = function() {
    playButton.innerHTML = 'play_arrow';
  };

  // Event listener for the mute button
  muteButton.addEventListener('click', function() {
    if (video.muted == false) {
      video.muted = true;
      muteButton.innerHTML = 'volume_off';
    } else {
      video.muted = false;
      muteButton.innerHTML = 'volume_up';
    }
  });

  // Event handler for the plusTen button
  plusTenButton.addEventListener('click', function() {
    video.currentTime = Math.min(video.currentTime + 10, video.duration);
  });

  // Event handler for the plusFive button
  plusFiveButton.addEventListener('click', function() {
    video.currentTime = Math.min(video.currentTime + 5, video.duration);
  });

  // Event handler for the plusOne button
  plusOneButton.addEventListener('click', function() {
    video.currentTime = Math.min(video.currentTime + 1, video.duration);
  });

  // Event handler for the minusOne button
  minusOneButton.addEventListener('click', function() {
    video.currentTime = Math.max(video.currentTime - 1, 0);
  });

  // Event handler for the minusFive button
  minusFiveButton.addEventListener('click', function() {
    video.currentTime = Math.max(video.currentTime - 5, 0);
  });

  // Event handler for the minusTen button
  minusTenButton.addEventListener('click', function() {
    video.currentTime = Math.max(video.currentTime - 10, 0);
  });

  // Event listener for the seek bar
  seekBar.addEventListener('input', function() {
    const time = video.duration * seekBar.value / 100;
    video.currentTime = time;
  });

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
    seekBar.value = 0;
    canvas.width = Math.floor($(video).width());
    canvas.height = Math.floor($(video).height());
  });

  // Update the seek bar as the video plays
  video.addEventListener('timeupdate', function() {
    const value = 100 / video.duration * video.currentTime;
    seekBar.value = value;
    seekBar.style.backgroundImage = 'linear-gradient(to right,' + ' #2497E3, #2497E3 ' + value + '%, #ffffff ' + value + '%, #ffffff)';
    currentTime.innerHTML = thymeUtility.secondsToTime(video.currentTime);
  });

  // Pause the video when the seek handle is being dragged
  seekBar.addEventListener('mousedown', function() {
    video.dataset.paused = video.paused;
    video.pause();
  });

  // Play the video when the seek handle is dropped
  seekBar.addEventListener('mouseup', function() {
    if (video.dataset.paused !== 'true') {
      video.play();
    }
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
