/* a boolean that helps to deactivate all key listeners
   for the time the annotation modal opens and the user
   has to write text into the command box */
var lockKeyListeners = false;

/* when callig the updateMarkers() method this will be used to save an
   array containing all annotations */
var annotations = null;

/* helps to find the annotation that is currently shown in the
   annotation area */
var activeAnnotationId = 0;

/* if the window width (in px) gets below this threshold value, hide the control bar
   (default value) */
var hideControlBarThreshold = {
  x: 850,
  y: 500
};

// return the start time of the next chapter relative to a given time in seconds
nextChapterStart = function(seconds) {
  var chapters = document.getElementById('chapters');
  var times = JSON.parse(chapters.dataset.times);
  if (times.length == 0) {
    return;
  }
  var i = 0;
  while (i < times.length) {
    if (times[i] > seconds) {
      return times[i];
    }
    ++i;
  }
};

previousChapterStart = function(seconds) {
  var chapters = document.getElementById('chapters');
  var times = JSON.parse(chapters.dataset.times);
  if (times.length == 0) {
    return;
  }
  var i = times.length - 1;
  while (i > -1) {
    if (times[i] < seconds) {
      if (seconds - times[i] > 3) {
        return times[i];
      }
      if (i > 0) {
        return times[i - 1];
      }
    }
    --i;
  }
};

showControlBar = function() {
  $('#video-controlBar').css('visibility', 'visible');
  $('#video').css('cursor', '');
};

hideControlBar = function() {
  $('#video-controlBar').css('visibility', 'hidden');
  $('#video').css('cursor', 'none');
};

// hide control bar after 3 seconds of inactivity
idleHideControlBar = function() {
  var t = void 0;
  resetTimer = function() {
    clearTimeout(t);
    t = setTimeout(hideControlBar, 3000);
  };
  window.onload = resetTimer;
  window.onmousemove = resetTimer;
  window.onmousedown = resetTimer;
  window.ontouchstart = resetTimer;
  window.onclick = resetTimer;
};

// material icons that represent different media types
iconClass = function(type) {
  if (type == 'video') {
    return 'video_library';
  } else if (type == 'text') {
    return 'library_books';
  } else if (type == 'quiz') {
    return 'games';
  } else if (type == 'info') {
    return 'info';
  }
};

/* returns the jQuery object of all metadata elements that start after the
   given time in seconds */
metadataAfter = function(seconds) {
  var metaList = document.getElementById('metadata');
  var times = JSON.parse(metaList.dataset.times);
  if (times.length == 0) {
    return $();
  }
  var i = 0;
  while (i < times.length) {
    if (times[i] > seconds) {
      var $nextMeta = $('#m-' + $.escapeSelector(times[i]));
      return $nextMeta.add($nextMeta.nextAll());
    }
    ++i;
  }
  return $();
};

/* returns the jQuery object of all metadata elements that start before the
   given time in seconds */
metadataBefore = function(seconds) {
  return $('[id^="m-"]').not(metadataAfter(seconds));
};

/* for a given time, show all metadata elements that start before this time
   and hide all that start later */
metaIntoView = function(time) {
  metadataAfter(time).hide();
  var $before = metadataBefore(time);
  $before.show();
  var previousLength = $before.length;
  if (previousLength > 0) {
    $before.get(previousLength - 1).scrollIntoView();
  }
};

// set up everything: read out track data and initialize html elements
setupHypervideo = function() {
  var $chapterList = $('#chapters');
  var $metaList = $('#metadata');
  var video = $('#video').get(0);
  var backButton = document.getElementById('back-button');
  if (video == null) {
    return;
  }
  document.body.style.backgroundColor = 'black';
  var chaptersElement = $('#video track[kind="chapters"]').get(0);
  var metadataElement = $('#video track[kind="metadata"]').get(0);

  // set up back button (transports back to the current chapter)
  displayBackButton = function() {
    backButton.dataset.time = video.currentTime;
    var currentChapter = $('#chapters .current');
    if (currentChapter.length > 0) {
      var backInfo = currentChapter.data('text').split(':', 1)[0];
      if ((backInfo != null) && backInfo.length > 20) {
        backInfo = backButton.dataset.back;
      } else {
        backInfo = backButton.dataset.backto + backInfo;
      }
      $(backButton).empty().append(backInfo).show();
      renderLatex(backButton);
    }
  };

  // set up the chapter elements
  displayChapters = function() {
    var chaptersTrack;
    if (chaptersElement.readyState == 2 && (chaptersTrack = chaptersElement.track)) {
      chaptersTrack.mode = 'hidden';
      var i = 0;
      var times = [];
      // read out the chapter track cues and generate html elements for chapters,
      // run katex on them
      while (i < chaptersTrack.cues.length) {
        var cue = chaptersTrack.cues[i];
        var chapterName = cue.text;
        var start = cue.startTime;
        times.push(start);
        var $listItem = $("<li/>");
        var $link = $("<a/>", {
          id: 'c-' + start,
          text: chapterName
        });
        $chapterList.append($listItem.append($link));
        var chapterElement = $link.get(0);
        renderLatex(chapterElement);
        $link.data('text', chapterName);
        // if a chapter element is clicked, transport to chapter start time
        $link.on('click', function() {
          displayBackButton();
          video.currentTime = this.id.replace('c-', '');
        });
        ++i;
      }
      // store start times as data attribute
      $chapterList.get(0).dataset.times = JSON.stringify(times);
      $chapterList.show();
      // if the chapters cue changes (i.e. a switch between chapters), highlight
      // current chapter elment and scroll it into view, remove highlighting from
      // old chapter
      $(chaptersTrack).on('cuechange', function() {
        $('#chapters li a').removeClass('current');
        if (this.activeCues.length > 0) {
          var activeStart = this.activeCues[0].startTime;
          var chapter;
          if (chapter = document.getElementById('c-' + activeStart)) {
            $(chapter).addClass('current');
            chapter.scrollIntoView();
          }
        }
      });
    }
  };

  // set up the metadata elements
  displayMetadata = function() {
    if (metadataElement.readyState == 2 && (metaTrack = metadataElement.track)) {
      metaTrack.mode = 'hidden';
      var i = 0;
      var times = [];
      // read out the metadata track cues and generate html elements for
      // metadata, run katex on them
      while (i < metaTrack.cues.length) {
        var cue = metaTrack.cues[i];
        var meta = JSON.parse(cue.text);
        var start = cue.startTime;
        times.push(start);
        var $listItem = $('<li/>', {
          id: 'm-' + start
        });
        $listItem.hide();
        var $link = $('<a/>', {
          text: meta.reference,
          "class": 'item',
          id: 'l-' + start
        });
        var $videoIcon = $('<i/>', {
          text: 'video_library',
          "class": 'material-icons'
        });
        var $videoRef = $('<a/>', {
          href: meta.video,
          target: '_blank'
        });
        $videoRef.append($videoIcon);
        if (meta.video == null) {
          $videoRef.hide();
        }
        var $manIcon = $('<i/>', {
          text: 'library_books',
          "class": 'material-icons'
        });
        var $manRef = $('<a/>', {
          href: meta.manuscript,
          target: '_blank'
        });
        $manRef.append($manIcon);
        if (meta.manuscript == null) {
          $manRef.hide();
        }
        var $scriptIcon = $('<i/>', {
          text: 'menu_book',
          "class": 'material-icons'
        });
        var $scriptRef = $('<a/>', {
          href: meta.script,
          target: '_blank'
        });
        $scriptRef.append($scriptIcon);
        if (meta.script == null) {
          $scriptRef.hide();
        }
        var $quizIcon = $('<i/>', {
          text: 'videogame_asset',
          "class": 'material-icons'
        });
        var $quizRef = $('<a/>', {
          href: meta.quiz,
          target: '_blank'
        });
        $quizRef.append($quizIcon);
        if (meta.quiz == null) {
          $quizRef.hide();
        }
        var $extIcon = $('<i/>', {
          text: 'link',
          "class": 'material-icons'
        });
        var $extRef = $('<a/>', {
          href: meta.link,
          target: '_blank'
        });
        $extRef.append($extIcon);
        if (meta.link == null) {
          $extRef.hide();
        }
        var $description = $('<div/>', {
          text: meta.text,
          "class": 'mx-3'
        });
        var $explanation = $('<div/>', {
          text: meta.explanation,
          "class": 'm-3'
        });
        var $details = $('<div/>');
        $details.append($link).append($description).append($explanation);
        $icons = $('<div/>', {
          style: 'flex-shrink: 3; display: flex; flex-direction: column;'
        });
        $icons.append($videoRef).append($manRef).append($scriptRef).append($quizRef).append($extRef);
        $listItem.append($details).append($icons);
        $metaList.append($listItem);
        $videoRef.on('click', function() {
          video.pause();
        });
        $manRef.on('click', function() {
          video.pause();
        });
        $extRef.on('click', function() {
          video.pause();
        });
        $link.on('click', function() {
          displayBackButton();
          video.currentTime = this.id.replace('l-', '');
        });
        metaElement = $listItem.get(0);
        renderLatex(metaElement);
        ++i;
      }
      // store metadata start times as data attribute
      $metaList.get(0).dataset.times = JSON.stringify(times);
      // if user jumps to a new position in the video, display all metadata
      // that start before this time and hide all that start later
      $(video).on('seeked', function() {
        var time = video.currentTime;
        metaIntoView(time);
      });
      // if the metadata cue changes, highlight all current media and scroll
      // them into view
      $(metaTrack).on('cuechange', function() {
        var j = 0;
        var time = video.currentTime;
        $('#metadata li').removeClass('current');
        while (j < this.activeCues.length) {
          var activeStart = this.activeCues[j].startTime;
          var metalink;
          if (metalink = document.getElementById('m-' + activeStart)) {
            $(metalink).show();
            $(metalink).addClass('current');
          }
          ++j;
        }
        var currentLength = $('#metadata .current').length;
        if (currentLength > 0) {
          $('#metadata .current').get(length - 1).scrollIntoView();
        }
      });
    }
  };

  /* after video metadata have been loaded, display chapters and metadata in the
     interactive area
     Originally (and more appropriately, according to the standards),
     only the 'loadedmetadata' event was used. However, Firefox triggers this event too soon,
     i.e. when the readyStates for chapters and elements are 1 (loading) instead of 2 (loaded)
     for the events, see https://www.w3schools.com/jsref/event_oncanplay.asp */
  var initialChapters = true;
  var initialMetadata = true;

  video.addEventListener('loadedmetadata', function() {
    if (initialChapters && chaptersElement.readyState == 2) {
      displayChapters();
      initialChapters = false;
    }
    if (initialMetadata && metadataElement.readyState == 2) {
      displayMetadata();
      initialMetadata = false;
    }
  });

  video.addEventListener('canplay', function() {
    if (initialChapters && chaptersElement.readyState == 2) {
      displayChapters();
      initialChapters = false;
    }
    if (initialMetadata && metadataElement.readyState == 2) {
      displayMetadata();
      initialMetadata = false;
    }
  });
};

$(document).on('turbolinks:load', function() {
  var thymeContainer = document.getElementById('thyme-container');
  // no need for thyme if no thyme container on the page
  if (thymeContainer == null) {
    return;
  }
  // Video
  var video = document.getElementById('video');
  var thyme = document.getElementById('thyme');
  // Buttons
  var playButton = document.getElementById('play-pause');
  var muteButton = document.getElementById('mute');
  var iaButton = document.getElementById('ia-active');
  var iaClose = document.getElementById('ia-close');
  var fullScreenButton = document.getElementById('full-screen');
  var plusTenButton = document.getElementById('plus-ten');
  var minusTenButton = document.getElementById('minus-ten');
  var nextChapterButton = document.getElementById('next-chapter');
  var previousChapterButton = document.getElementById('previous-chapter');
  var backButton = document.getElementById('back-button');
  var emergencyButton = document.getElementById('emergency-button');
  var annotationsToggle = document.getElementById('annotations-toggle-check');
  // Sliders
  var seekBar = document.getElementById('seek-bar');
  var volumeBar = document.getElementById('volume-bar');
  // Selectors
  var speedSelector = document.getElementById('speed');
  // Time
  var currentTime = document.getElementById('current-time');
  var maxTime = document.getElementById('max-time');
  // ControlBar
  var videoControlBar = document.getElementById('video-controlBar');

  // User is teacher/editor for the given medium?
  // -> show toggle annotations button
  var mediumId = thyme.dataset.medium;
  $.ajax(Routes.check_annotation_visibility_path(mediumId), {
    type: 'GET',
    dataType: 'json',
    success: function(isPermitted) {
      if (isPermitted) {
        $('#volume-controls').css('left', '66%');
        $('#speed-control').css('left', '77%');
        $('#emergency-button').css('left', '86%');
        hideControlBarThreshold.x = 960;
        updateControlBarType();
      }
    }
  });

  // resizes the thyme container to the window dimensions, taking into account
  // whether the interactive area is displayed or hidden
  resizeContainer = function() {
    var height = $(window).height();
    var factor = $('#caption').is(':hidden') && $('#annotation-caption').is(':hidden') ? 1 : 1 / 0.82;
    var width = Math.floor((video.videoWidth * $(window).height() / video.videoHeight) * factor);
    if (width > $(window).width()) {
      var shrink = $(window).width() / width;
      height = Math.floor(height * shrink);
      width = $(window).width();
    }
    var top = Math.floor(0.5 * ($(window).height() - height));
    var left = Math.floor(0.5 * ($(window).width() - width));
    $('#thyme-container').css('height', height + 'px');
    $('#thyme-container').css('width', width + 'px');
    $('#thyme-container').css('top', top + 'px');
    $('#thyme-container').css('left', left + 'px');
    if (annotations == null) {
      updateMarkers();
    } else {
      rearrangeMarkers();
    }
  };

  // detect IE/edge and inform user that they are not suppported if necessary,
  // only use browser player
  if (document.documentMode || /Edge/.test(navigator.userAgent)) {
    alert($('body').data('badbrowser'));
    $('#caption').hide();
    $('#annotation-caption').hide();
    $('#video-controlBar').hide();
    video.style.width = '100%';
    video.controls = true;
    document.body.style.backgroundColor = 'black';
    resizeContainer();
    window.onresize = resizeContainer;
    return;
  }

  setupHypervideo();

  // on small mobile display, fall back to standard browser player
  mobileDisplay = function() {
    $('#caption').hide();
    $('#annotation-caption').hide();
    $('#video-controlBar').hide();
    video.controls = true;
    video.style.width = '100%';
  };

  // on large display, use anything thyme has to offer, disable native player
  largeDisplay = function() {
    video.controls = false;
    $('#caption').show();
    $('#annotation-caption').show();
    $('#video-controlBar').show();
    video.style.width = '82%';
    if (iaButton.dataset.status == 'false') {
      iaButton.innerHTML = 'remove_from_queue';
      $('#caption').hide();
      $('#annotation-caption').hide();
      video.style.width = '100%';
      $('#video-controlBar').css('width', '100%');
      $(window).trigger('resize');
    }
  };

  updateControlBarType = function() {
    // display native control bar if screen is very small
    if (window.matchMedia("screen and (max-width: " + hideControlBarThreshold.x + "px)").matches ||
       window.matchMedia("screen and (max-height: " + hideControlBarThreshold.y + "px)").matches) {
      mobileDisplay();
    }

    if (window.matchMedia("screen and (max-device-width: " + hideControlBarThreshold.x + "px)").matches ||
       window.matchMedia("screen and (max-device-height: " + hideControlBarThreshold.y + "px)").matches) {
      mobileDisplay();
    }

    // mediaQuery listener for very small screens
    var match_verysmall_x = window.matchMedia("screen and (max-width: " +
      hideControlBarThreshold.x + "px)");
    match_verysmall_x.addListener(function(result) {
      if (result.matches) {
        mobileDisplay();
      }
    });
    var match_verysmall_y = window.matchMedia("screen and (max-height: " +
      hideControlBarThreshold.y + "px)");
    match_verysmall_y.addListener(function(result) {
      if (result.matches) {
        mobileDisplay();
      }
    });

    var match_verysmalldevice_x = window.matchMedia("screen and (max-device-width: " +
      hideControlBarThreshold.x + "px)");
    match_verysmalldevice_x.addListener(function(result) {
      if (result.matches) {
        mobileDisplay();
      }
    });
    var match_verysmalldevice_y = window.matchMedia("screen and (max-device-height: " +
      hideControlBarThreshold.y + "px)");
    match_verysmalldevice_y.addListener(function(result) {
      if (result.matches) {
        mobileDisplay();
      }
    });

    // mediaQuery listener for normal screens
    var match_normal_x = window.matchMedia("screen and (min-width: " + (hideControlBarThreshold.x + 1) + "px)");
    match_normal_x.addListener(function(result) {
      var match_normal_y;
      match_normal_y = window.matchMedia("screen and (min-height: " + (hideControlBarThreshold.y + 1) + "px)");
      if (result.matches && match_normal_y.matches) {
        largeDisplay();
      }
    });
    var match_normal_y = window.matchMedia("screen and (min-height: " + (hideControlBarThreshold.y + 1) + "px)");
    match_normal_y.addListener(function(result) {
      match_normal_x = window.matchMedia("screen and (min-width: " + (hideControlBarThreshold.x + 1) + "px)");
      if (result.matches && match_normal_x.matches) {
        largeDisplay();
      }
    });

    var match_normaldevice_x = window.matchMedia("screen and (min-device-width: " +
      (hideControlBarThreshold.x + 1) + "px)");
    match_normaldevice_x.addListener(function(result) {
      var match_normaldevice_y;
      match_normaldevice_y = window.matchMedia("screen and (min-device-height: " +
        (hideControlBarThreshold.y + 1) + "px)");
      if (result.matches && match_normal_y.matches) {
        largeDisplay();
      }
    });
    var match_normaldevice_y = window.matchMedia("screen and (min-device-height: " +
      (hideControlBarThreshold.y + 1) + "px)");
    match_normaldevice_y.addListener(function(result) {
      match_normaldevice_x = window.matchMedia("screen and (min-device-width: " +
        (hideControlBarThreshold.x + 1) + "px)");
      if (result.matches && match_normal_x.matches) {
        largeDisplay();
      }
    });
  };

  updateControlBarType();

  window.onresize = resizeContainer;
  video.onloadedmetadata = resizeContainer;

  idleHideControlBar();

  // if mouse is moved or screen is toiched, show control bar
  video.addEventListener('mouseover', showControlBar, false);
  video.addEventListener('mousemove', showControlBar, false);
  video.addEventListener('touchstart', showControlBar, false);

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

  // Event handler for the minusTen button
  minusTenButton.addEventListener('click', function() {
    video.currentTime = Math.max(video.currentTime - 10, 0);
  });

  // Event handler for the nextChapter button
  nextChapterButton.addEventListener('click', function() {
    var next = nextChapterStart(video.currentTime);
    if (next != null) {
      video.currentTime = nextChapterStart(video.currentTime);
    }
  });

  // Event handler for the previousChapter button
  previousChapterButton.addEventListener('click', function() {
    var previous = previousChapterStart(video.currentTime);
    if (previous != null) {
      video.currentTime = previousChapterStart(video.currentTime);
    }
  });

  // Event handler for the emergency button
  emergencyButton.addEventListener('click', function() {
    video.pause();
    $.ajax(Routes.new_annotation_path(), {
      type: 'GET',
      dataType: 'script',
      data: {
        total_seconds: video.currentTime,
        mediumId: thyme.dataset.medium
      }
    });
    // When the modal opens, all key listeners must be
    // deactivated until the modal gets closed again
    lockKeyListeners = true;
    $('#annotation-modal').on('hidden.bs.modal', function() {
      lockKeyListeners = false;
    });
  });

  if (annotationsToggle !== null) {
    annotationsToggle.addEventListener('click', function() {
      updateMarkers();
    });
  }

  // Update annotations after submitting the annotations form
  $(document).on('click', '#submit-button', function() {
    /* NOTE:
       Updating might take some time on the backend,
       so I added a slight delay.
       I couldn't think of an easy way to let the script
       wait for the update to complete (as with the delete button),
       but it might be possible! */
    setTimeout(updateMarkers, 500);
  });

  // Update annotations after deleting an annotation
  $(document).on('click', '#delete-button', function() {
    var annotationId = Number(document.getElementById('annotation_id').textContent);
    $.ajax(Routes.annotation_path(annotationId), {
      type: 'DELETE',
      dataType: 'json',
      data: {
        annotationId: annotationId
      },
      success: function() {
        updateMarkers();
        $('#annotation-close-button').click();
      }
    });
  });

  // Event handler for speed speed selector
  speedSelector.addEventListener('change', function() {
    if (video.preservesPitch != null) {
      video.preservesPitch = true;
    } else if (video.mozPreservesPitch != null) {
      video.mozPreservesPitch = true;
    } else if (video.webkitPreservesPitch != null) {
      video.webkitPreservesPitch = true;
    }
    video.playbackRate = this.options[this.selectedIndex].value;
  });

  // Event handler for interactive area activation button
  iaButton.addEventListener('click', function() {
    if (iaButton.dataset.status == 'true') {
      iaButton.innerHTML = 'remove_from_queue';
      iaButton.dataset.status = 'false';
      $('#caption').hide();
      $('#annotation-caption').hide();
      video.style.width = '100%';
      $('#video-controlBar').css('width', '100%');
      $(window).trigger('resize');
    } else {
      iaButton.innerHTML = 'add_to_queue';
      iaButton.dataset.status = 'true';
      video.style.width = '82%';
      $('#video-controlBar').css('width', '82%');
      $('#caption').show();
      $('#annotation-caption').show();
      $(window).trigger('resize');
    }
  });

  // Event Handler for Back Button
  backButton.addEventListener('click', function() {
    video.currentTime = this.dataset.time;
    $(backButton).hide();
    $('#back-reference').hide();
  });

  // Event handler for close interactive area button
  iaClose.addEventListener('click', function() {
    $(iaButton).trigger('click');
  });

  // Event listener for the full-screen button
  // unfortunately, lots of brwoser specific code
  fullScreenButton.addEventListener('click', function() {
    if (fullScreenButton.dataset.status == 'true') {
      if (document.exitFullscreen) {
        document.exitFullscreen();
      } else if (document.mozCancelFullScreen) {
        document.mozCancelFullScreen();
      } else if (document.webkitExitFullscreen) {
        document.webkitExitFullscreen();
      }
    } else {
      if (thymeContainer.requestFullscreen) {
        thymeContainer.requestFullscreen();
      } else if (thymeContainer.mozRequestFullScreen) {
        thymeContainer.mozRequestFullScreen();
      } else if (thymeContainer.webkitRequestFullscreen) {
        thymeContainer.webkitRequestFullscreen();
      }
    }
  });

  document.onfullscreenchange = function() {
    if (document.fullscreenElement !== null) {
      fullScreenButton.innerHTML = 'fullscreen_exit';
      fullScreenButton.dataset.status = 'true';
    } else {
      fullScreenButton.innerHTML = 'fullscreen';
      fullScreenButton.dataset.status = 'false';
      /* brute force patch: apparently, after exiting fullscreen mode,
        window.onresize is triggered twice(!), the second time with incorrect
        window height data, which results in a video area not quite filling
        the whole window. The next line resizes the container again. */
      setTimeout(resizeContainer, 20);
    }
  };

  document.onwebkitfullscreenchange = function() {
    if (document.webkitFullscreenElement !== null) {
      fullScreenButton.innerHTML = 'fullscreen_exit';
      fullScreenButton.dataset.status = 'true';
    } else {
      fullScreenButton.innerHTML = 'fullscreen';
      fullScreenButton.dataset.status = 'false';
      setTimeout(resizeContainer, 20);
    }
  };

  document.onmozfullscreenchange = function() {
    if (document.mozFullScreenElement !== null) {
      fullScreenButton.innerHTML = 'fullscreen_exit';
      fullScreenButton.dataset.status = 'true';
    } else {
      fullScreenButton.innerHTML = 'fullscreen';
      fullScreenButton.dataset.status = 'false';
      setTimeout(resizeContainer, 20);
    }
  };

  // Event listeners for the seek bar
  seekBar.addEventListener('input', function() {
    var time = video.duration * seekBar.value / 100;
    video.currentTime = time;
  });
  
  // if mouse is moved over seek bar, display tooltip with current chapter
  seekBar.addEventListener('mousemove', function(evt) {
    var positionInfo = seekBar.getBoundingClientRect();
    var width = positionInfo.width;
    var left = positionInfo.left;
    var measuredSeconds = ((evt.pageX - left) / width) * video.duration;
    var seconds = Math.min(measuredSeconds, video.duration);
    seconds = Math.max(seconds, 0);
    var previous = previousChapterStart(seconds);
    var info = $('#c-' + $.escapeSelector(previous)).text().split(':')[0];
    seekBar.setAttribute('title', info);
  });
  
  // if videomedtadata have been loaded, set up video length, volume bar and
  // seek bar
  video.addEventListener('loadedmetadata', function() {
    maxTime.innerHTML = secondsToTime(video.duration);
    volumeBar.value = video.volume;
    volumeBar.style.backgroundImage = 'linear-gradient(to right,' + ' #2497E3, #2497E3 ' + video.volume * 100 + '%, #ffffff ' + video.volume * 100 + '%, #ffffff)';
    if (video.dataset.time != null) {
      var time = video.dataset.time;
      video.currentTime = time;
      seekBar.value = video.currentTime / video.duration * 100;
    } else {
      seekBar.value = 0;
    }
  });
  
  // Update the seek bar as the video plays
  // uses a gradient for seekbar video time visualization
  video.addEventListener('timeupdate', function() {
    var value = 100 / video.duration * video.currentTime;
    seekBar.value = value;
    seekBar.style.backgroundImage = 'linear-gradient(to right,' + ' #2497E3, #2497E3 ' + value + '%, #ffffff ' + value + '%, #ffffff)';
    currentTime.innerHTML = secondsToTime(video.currentTime);
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
  volumeBar.addEventListener('input', function() {
    var value = volumeBar.value;
    video.volume = value;
  });

  video.addEventListener('volumechange', function() {
    var value = video.volume;
    volumeBar.value = value;
    volumeBar.style.backgroundImage = 'linear-gradient(to right,' + ' #2497E3, #2497E3 ' +
    value * 100 + '%, #ffffff ' + value * 100 + '%, #ffffff)';
  });

  video.addEventListener('click', function() {
    if (video.paused == true) {
      video.play();
    } else {
      video.pause();
    }
    showControlBar();
  });
  
  /* thyme can be used by keyboard as well
     Arrow up - next chapter
     Arrow down - previous chapter
     Arrow right - plus ten seconds
     Arrow left - minus ten seconds
     f - fullscreen
     Page up - volume up
     Page down - volume down
     m - mute
     i - toggle interactive area */
  window.addEventListener('keydown', function(evt) {
    if (lockKeyListeners == true) {
      return;
    }
    var key = evt.key;
    if (key == ' ') {
      if (video.paused == true) {
        video.play();
      } else {
        video.pause();
      }
    } else if (key == 'ArrowUp') {
      $(nextChapterButton).trigger('click');
    } else if (key == 'ArrowDown') {
      $(previousChapterButton).trigger('click');
    } else if (key == 'ArrowRight') {
      $(plusTenButton).trigger('click');
    } else if (key == 'ArrowLeft') {
      $(minusTenButton).trigger('click');
    } else if (key == 'f') {
      $(fullScreenButton).trigger('click');
    } else if (key == 'PageUp') {
      video.volume = Math.min(video.volume + 0.1, 1);
    } else if (key == 'PageDown') {
      video.volume = Math.max(video.volume - 0.1, 0);
    } else if (key == 'm') {
      $(muteButton).trigger('click');
    } else if (key == 'i') {
      $(iaButton).trigger('click');
    }
  });
  
  // updates the annotation markers
  updateMarkers = function() {
    var mediumId = thyme.dataset.medium;
    var toggled = $('#annotations-toggle-check').is(":checked");
    $.ajax(Routes.update_markers_path(), {
      type: 'GET',
      dataType: 'json',
      data: {
        mediumId: mediumId,
        toggled: toggled
      },
      success: function(annots) {
        annotations = annots;
        if (annotations == null) {
          return;
        }
        rearrangeMarkers();
        var flag = false;
        for (let annotation of annotations) {
          if (annotation.id == activeAnnotationId) {
            updateAnnotationArea(annotation);
            flag = true;
          }
        }
        if (flag == false && $('#annotation-caption').is(":visible") == true) {
          $('#annotation-caption').hide();
          $('#caption').show();
        }
      }
    });
  };

  rearrangeMarkers = function() {
    $('#markers').empty();
    sortAnnotations(annotations);
    for (const annotation of annotations) {
      createMarker(annotation);
    }
  };

  // an auxiliary method for "updateMarkers()" creating a single marker
  createMarker = function(annotation) {
    // create marker
    var markerStr = '<span id="marker-' + annotation.id + '">' +
                      '<svg width="15" height="15">' +
                      '<polygon points="1,1 9,1 5,10"' +
                        'style="fill:' + annotation.color + ';' +
                        'stroke:black;' +
                        'stroke-width:1;' +
                        'fill-rule:evenodd;"/>' +
                      '</svg>' +
                    '</span>';
    $('#markers').append(markerStr);
    var marker = $('#marker-' + annotation.id);
    var size = seekBar.clientWidth - 15;
    var ratio = timestampToMillis(annotation.timestamp) / video.duration;
    var offset = marker.parent().offset().left + ratio * size + 3;
    marker.offset({ left: offset });
    marker.on('click', function() {
      if (iaButton.dataset.status == "false") {
        $(iaButton).trigger('click');
      }
      $('#caption').hide();
      updateAnnotationArea(annotation);
      $('#annotation-caption').show();
    });
  };

  categoryLocale = function(category, subtext) {
    var c, s;
    switch (category) {
      case "note":
        c = document.getElementById('annotation-locales').dataset.note;
        break;
      case "content":
        c = document.getElementById('annotation-locales').dataset.content;
        break;
      case "mistake":
        c = document.getElementById('annotation-locales').dataset.mistake;
        break;
      case "presentation":
        c = document.getElementById('annotation-locales').dataset.presentation;
    }
    if (subtext == null) {
      return c;
    }
    switch (subtext) {
      case "definition":
        s = document.getElementById('annotation-locales').dataset.definition;
        break;
      case "strategy":
        s = document.getElementById('annotation-locales').dataset.strategy;
        break;
      case "presentation":
        s = document.getElementById('annotation-locales').dataset.presentation;
    }
    return c + " (" + s + ")";
  };
  
  updateAnnotationArea = function(annotation) {
    var activeAnnotationId = annotation.id;
    var head = categoryLocale(annotation.category, annotation.subtext);
    var comment = annotation.comment.replaceAll('\n', '<br>');
    var headColor = lightenUp(annotation.color, 2);
    var backgroundColor = lightenUp(annotation.color, 3);
    $('#annotation-infobar').empty().append(head);
    $('#annotation-infobar').css('background-color', headColor);
    $('#annotation-infobar').css('text-align', 'center');
    $('#annotation-comment').empty().append(comment);
    $('#annotation-caption').css('background-color', backgroundColor);
    // remove old listeners
    $('#annotation-previous-button').off('click');
    $('#annotation-next-button').off('click');
    $('#annotation-goto-button').off('click');
    $('#annotation-edit-button').off('click');
    $('#annotation-close-button').off('click');
    // previous annotation listener
    $('#annotation-previous-button').on('click', function() {
      for (var i = 0; i < annotations.length; i++) {
        if (i != 0 && annotations[i] == annotation) {
          updateAnnotationArea(annotations[i - 1])
        }
      }
    });
    // next annotation Listener
    $('#annotation-next-button').on('click', function() {
      for (var i = 0; i < annotations.length; i++) {
        if (i != annotations.length - 1 && annotations[i] == annotation) {
          updateAnnotationArea(annotations[i + 1])
        }
      }
    });
    // goto listener
    $('#annotation-goto-button').on('click', function() {
      video.currentTime = timestampToMillis(annotation.timestamp);
    });
    // edit listener
    $('#annotation-edit-button').on('click', function() {
      lockKeyListeners = true;
      $.ajax(Routes.edit_annotation_path(annotation.id), {
        type: 'GET',
        dataType: 'script',
        data: {
          annotationId: annotation.id
        },
        success: function(permitted) {
          if (permitted == "false") {
            alert(document.getElementById('annotation-locales').dataset.permission);
          }
        },
        error: function(e) {
          console.log(e);
        }
      });
    });
    // close listener
    $('#annotation-close-button').on('click', function() {
      activeAnnotationId = 0;
      $('#annotation-caption').hide();
      $('#caption').show();
    });
    // LaTex
    renderLatex(document.getElementById('annotation-comment'));
  };
});