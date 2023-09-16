// convert given dataURL to Blob, used for converting screenshot canvas to png
function dataURLtoBlob(dataURL) {
  // Decode the dataURL
  var binary = atob(dataURL.split(',')[1]);
  // Create 8-bit unsigned array
  var array = [];
  var i = 0;
  while (i < binary.length) {
    array.push(binary.charCodeAt(i));
    i++;
  }
  // Return our Blob object
  return new Blob([new Uint8Array(array)], {
    type: 'image/png'
  });
};

$(document).on('turbolinks:load', function() {
  var thymeEdit = document.getElementById('thyme-edit');
  if (thymeEdit == null) {
    return;
  }
  var mediumId = thymeEdit.dataset.medium;
  // Video
  var video = document.getElementById('video-edit');
  // Buttons
  var playButton = document.getElementById('play-pause');
  var muteButton = document.getElementById('mute');
  var plusTenButton = document.getElementById('plus-ten');
  var plusFiveButton = document.getElementById('plus-five');
  var plusOneButton = document.getElementById('plus-one');
  var minusOneButton = document.getElementById('minus-one');
  var minusFiveButton = document.getElementById('minus-five');
  var minusTenButton = document.getElementById('minus-ten');
  var addItemButton = document.getElementById('add-item');
  var addReferenceButton = document.getElementById('add-reference');
  var addScreenshotButton = document.getElementById('add-screenshot');
  // Sliders
  var seekBar = document.getElementById('seek-bar');
  var volumeBar = document.getElementById('volume-bar');
  // Times
  var currentTime = document.getElementById('current-time');
  var maxTime = document.getElementById('max-time');
  // Screenshot Canvas
  var canvas = document.getElementById('snapshot');

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
    var time;
    time = video.duration * seekBar.value / 100;
    video.currentTime = time;
  });

  // Event listener for addItem button
  addItemButton.addEventListener('click', function() {
    video.pause();
    // round time down to three decimal digits
    var time = video.currentTime;
    var intTime = Math.floor(time);
    var roundTime = intTime + Math.floor((time - intTime) * 1000) / 1000;
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
    var time = video.currentTime;
    var intTime = Math.floor(time);
    var roundTime = intTime + Math.floor((time - intTime) * 1000) / 1000;
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
    var context = canvas.getContext('2d');
    context.drawImage(video, 0, 0, canvas.width, canvas.height);
    var base64image = canvas.toDataURL('image/png');
    // Get our file
    var file = dataURLtoBlob(base64image);
    // Create new form data
    var fd = new FormData;
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
    var value = 100 / video.duration * video.currentTime;
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
    var value = volumeBar.value;
    video.volume = value;
  });

  video.addEventListener('volumechange', function() {
    var value = video.volume;
    volumeBar.value = value;
    volumeBar.style.backgroundImage = 'linear-gradient(to right,' + ' #2497E3, #2497E3 ' + value * 100 + '%, #ffffff ' + value * 100 + '%, #ffffff)';
  });
});
