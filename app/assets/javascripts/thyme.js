function showControlBar() {
  $('#video-controlBar').css('visibility', 'visible');
  $('#video').css('cursor', '');
};

function hideControlBar() {
  $('#video-controlBar').css('visibility', 'hidden');
  $('#video').css('cursor', 'none');
};

// hide control bar after 3 seconds of inactivity
function idleHideControlBar() {
  let t = void 0;
  function resetTimer() {
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
function iconClass(type) {
  if (type === 'video') {
    return 'video_library';
  } else if (type === 'text') {
    return 'library_books';
  } else if (type === 'quiz') {
    return 'games';
  } else if (type === 'info') {
    return 'info';
  }
};

/* returns the jQuery object of all metadata elements that start after the
   given time in seconds */
function metadataAfter(seconds) {
  const metaList = document.getElementById('metadata');
  const times = JSON.parse(metaList.dataset.times);
  if (times.length === 0) {
    return $();
  }
  let i = 0;
  while (i < times.length) {
    if (times[i] > seconds) {
      const $nextMeta = $('#m-' + $.escapeSelector(times[i]));
      return $nextMeta.add($nextMeta.nextAll());
    }
    ++i;
  }
  return $();
};

/* returns the jQuery object of all metadata elements that start before the
   given time in seconds */
function metadataBefore(seconds) {
  return $('[id^="m-"]').not(metadataAfter(seconds));
};

/* for a given time, show all metadata elements that start before this time
   and hide all that start later */
function metaIntoView(time) {
  metadataAfter(time).hide();
  const $before = metadataBefore(time);
  $before.show();
  const previousLength = $before.length;
  if (previousLength > 0) {
    $before.get(previousLength - 1).scrollIntoView();
  }
};

// set up everything: read out track data and initialize html elements
function setupHypervideo() {
  const $chapterList = $('#chapters');
  const $metaList = $('#metadata');
  const video = $('#video').get(0);
  const backButton = document.getElementById('back-button');
  if (video === null) {
    return;
  }
  document.body.style.backgroundColor = 'black';
  const chaptersElement = $('#video track[kind="chapters"]').get(0);
  const metadataElement = $('#video track[kind="metadata"]').get(0);

  // set up back button (transports back to the current chapter)
  function displayBackButton() {
    backButton.dataset.time = video.currentTime;
    const currentChapter = $('#chapters .current');
    if (currentChapter.length > 0) {
      let backInfo = currentChapter.data('text').split(':', 1)[0];
      if ((backInfo != null) && backInfo.length > 20) {
        backInfo = backButton.dataset.back;
      } else {
        backInfo = backButton.dataset.backto + backInfo;
      }
      $(backButton).empty().append(backInfo).show();
      thymeUtility.renderLatex(backButton);
    }
  };

  // set up the chapter elements
  function displayChapters() {
    let chaptersTrack;
    if (chaptersElement.readyState === 2 && (chaptersTrack = chaptersElement.track)) {
      chaptersTrack.mode = 'hidden';
      let i = 0;
      let times = [];
      // read out the chapter track cues and generate html elements for chapters,
      // run katex on them
      while (i < chaptersTrack.cues.length) {
        const cue = chaptersTrack.cues[i];
        const chapterName = cue.text;
        const start = cue.startTime;
        times.push(start);
        const $listItem = $("<li/>");
        const $link = $("<a/>", {
          id: 'c-' + start,
          text: chapterName
        });
        $chapterList.append($listItem.append($link));
        const chapterElement = $link.get(0);
        thymeUtility.renderLatex(chapterElement);
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
          const activeStart = this.activeCues[0].startTime;
          let chapter;
          if (chapter = document.getElementById('c-' + activeStart)) {
            $(chapter).addClass('current');
            chapter.scrollIntoView();
          }
        }
      });
    }
  };

  // set up the metadata elements
  function displayMetadata() {
    if (metadataElement.readyState === 2 && (metaTrack = metadataElement.track)) {
      metaTrack.mode = 'hidden';
      let i = 0;
      let times = [];
      // read out the metadata track cues and generate html elements for
      // metadata, run katex on them
      while (i < metaTrack.cues.length) {
        const cue = metaTrack.cues[i];
        const meta = JSON.parse(cue.text);
        const start = cue.startTime;
        times.push(start);
        const $listItem = $('<li/>', {
          id: 'm-' + start
        });
        $listItem.hide();
        const $link = $('<a/>', {
          text: meta.reference,
          "class": 'item',
          id: 'l-' + start
        });
        const $videoIcon = $('<i/>', {
          text: 'video_library',
          "class": 'material-icons'
        });
        const $videoRef = $('<a/>', {
          href: meta.video,
          target: '_blank'
        });
        $videoRef.append($videoIcon);
        if (meta.video === null) {
          $videoRef.hide();
        }
        const $manIcon = $('<i/>', {
          text: 'library_books',
          "class": 'material-icons'
        });
        const $manRef = $('<a/>', {
          href: meta.manuscript,
          target: '_blank'
        });
        $manRef.append($manIcon);
        if (meta.manuscript === null) {
          $manRef.hide();
        }
        const $scriptIcon = $('<i/>', {
          text: 'menu_book',
          "class": 'material-icons'
        });
        const $scriptRef = $('<a/>', {
          href: meta.script,
          target: '_blank'
        });
        $scriptRef.append($scriptIcon);
        if (meta.script === null) {
          $scriptRef.hide();
        }
        const $quizIcon = $('<i/>', {
          text: 'videogame_asset',
          "class": 'material-icons'
        });
        const $quizRef = $('<a/>', {
          href: meta.quiz,
          target: '_blank'
        });
        $quizRef.append($quizIcon);
        if (meta.quiz === null) {
          $quizRef.hide();
        }
        const $extIcon = $('<i/>', {
          text: 'link',
          "class": 'material-icons'
        });
        const $extRef = $('<a/>', {
          href: meta.link,
          target: '_blank'
        });
        $extRef.append($extIcon);
        if (meta.link === null) {
          $extRef.hide();
        }
        const $description = $('<div/>', {
          text: meta.text,
          "class": 'mx-3'
        });
        const $explanation = $('<div/>', {
          text: meta.explanation,
          "class": 'm-3'
        });
        const $details = $('<div/>');
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
        thymeUtility.renderLatex(metaElement);
        ++i;
      }
      // store metadata start times as data attribute
      $metaList.get(0).dataset.times = JSON.stringify(times);
      // if user jumps to a new position in the video, display all metadata
      // that start before this time and hide all that start later
      $(video).on('seeked', function() {
        const time = video.currentTime;
        metaIntoView(time);
      });
      // if the metadata cue changes, highlight all current media and scroll
      // them into view
      $(metaTrack).on('cuechange', function() {
        let j = 0;
        const time = video.currentTime;
        $('#metadata li').removeClass('current');
        while (j < this.activeCues.length) {
          const activeStart = this.activeCues[j].startTime;
          let metalink;
          if (metalink = document.getElementById('m-' + activeStart)) {
            $(metalink).show();
            $(metalink).addClass('current');
          }
          ++j;
        }
        const currentLength = $('#metadata .current').length;
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
  let initialChapters = true;
  let initialMetadata = true;

  video.addEventListener('loadedmetadata', function() {
    if (initialChapters && chaptersElement.readyState === 2) {
      displayChapters();
      initialChapters = false;
    }
    if (initialMetadata && metadataElement.readyState === 2) {
      displayMetadata();
      initialMetadata = false;
    }
  });

  video.addEventListener('canplay', function() {
    if (initialChapters && chaptersElement.readyState === 2) {
      displayChapters();
      initialChapters = false;
    }
    if (initialMetadata && metadataElement.readyState === 2) {
      displayMetadata();
      initialMetadata = false;
    }
  });
};

$(document).on('turbolinks:load', function() {
  const thymeContainer = document.getElementById('thyme-container');
  // no need for thyme if no thyme container on the page
  if (thymeContainer === null) {
    return;
  }
  // Video
  thymeAttributes.video = document.getElementById('video');
  const video = thymeAttributes.video;
  const thyme = document.getElementById('thyme');
  // initialize medium id
  thymeAttributes.mediumId = thyme.dataset.medium;
  // initialize marker bar
  thymeAttributes.markerBarID = 'markers';
  // Buttons
  annotationsToggle = new AnnotationsToggle('annotations-toggle');
  annotationsToggle.add();
  (new EmergencyButton('emergency-button')).add();
  (new FullScreenButton('full-screen', thymeContainer)).add();
  (new MinusTenButton('minus-ten')).add();
  (new MuteButton('mute')).add();
  (new NextChapterButton('next-chapter')).add();
  (new PlayButton('play-pause')).add();  
  (new PlusTenButton('plus-ten')).add();
  (new PreviousChapterButton('previous-chapter')).add();
  (new SpeedSelector('speed')).add();
  // Sliders
  (new VolumeBar('volume-bar')).add();
  seekBar = new SeekBar('seek-bar');
  seekBar.add();
  seekBar.addChapterTooltips();
  // Buttons
  const iaButton = document.getElementById('ia-active');
  const iaClose = document.getElementById('ia-close');
  const backButton = document.getElementById('back-button');

  // Manage large and small display
  function largeDisplayFunc() {
    video.style.width = '82%';
    if (iaButton.dataset.status === 'false') {
      iaButton.innerHTML = 'remove_from_queue';
      $('#caption').hide();
      $('#annotation-caption').hide();
      video.style.width = '100%';
      $('#video-controlBar').css('width', '100%');
      $(window).trigger('resize');
    }
  }
  const elements = [$('#caption'), $('#annotation-caption'), $('#video-controlBar')];
  const displayManager = new DisplayManager(elements, largeDisplayFunc);

  // annotation area
  const annotationArea = new AnnotationArea(true);
  thymeAttributes.annotationArea = annotationArea;
  // annotation manager
  function colorFunc(annotation) {
    return annotation.color;
  }
  function strokeColorFunc(annotation) {
    return 'black';
  }
  function sizeFunc(annotation) {
    return false;
  }
  function onClick(annotation) {
    $('#caption').hide();
    annotationArea.update(annotation);
    annotationArea.show();
  }
  function onUpdate() {
    const a = AnnotationManager.find(thymeAttributes.activeAnnotationId);
    annotationArea.update(a);
  }
  const annotationManager = new AnnotationManager(colorFunc, strokeColorFunc, sizeFunc,
                                                  onClick, onUpdate);
  thymeAttributes.annotationManager = annotationManager;
  // onShow and onUpdate definition for the annotation area
  function onShow() {
    video.style.width = '82%';
    $('#video-controlBar').css('width', '82%');
    iaButton.innerHTML = 'add_to_queue';
    iaButton.dataset.status = 'true';
    annotationManager.updateMarkers();
  }
  function onHide() {
    video.style.width = '100%';
    $('#video-controlBar').css('width', '100%');
    iaButton.innerHTML = 'remove_from_queue';
    iaButton.dataset.status = 'false';
    annotationManager.updateMarkers();
    resizeContainer();
  }
  annotationArea.onShow = onShow;
  annotationArea.onHide = onHide;

  // resizes the thyme container to the window dimensions, taking into account
  // whether the interactive area is displayed or hidden
  function resizeContainer() {
    const factor = $('#caption').is(':hidden') && $('#annotation-caption').is(':hidden') ? 1 : 1 / 0.82;
    resize.resizeContainer(thymeContainer, factor);
    if (thymeAttributes.annotations === null) {
      annotationManager.updateAnnotations(annotationsToggle.getValue());
    } else {
      annotationManager.updateMarkers();
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

  function updateControlBarType() {
    displayManager.updateControlBarType();
  };

  updateControlBarType();

  window.onresize = resizeContainer;
  video.onloadedmetadata = resizeContainer;

  idleHideControlBar();

  // if mouse is moved or screen is toiched, show control bar
  video.addEventListener('mouseover', showControlBar, false);
  video.addEventListener('mousemove', showControlBar, false);
  video.addEventListener('touchstart', showControlBar, false);

  // Update annotations after submitting the annotations form
  $(document).on('click', '#submit-button', function() {
    /* NOTE:
       Updating might take some time on the backend,
       so I added a slight delay.
       I couldn't think of an easy way to let the script
       wait for the update to complete (as with the delete button),
       but it might be possible! */
    setTimeout(annotationManager.updateAnnotations(annotationsToggle.getValue()), 500);
  });

  // Update annotations after deleting an annotation
  $(document).on('click', '#delete-button', function() {
    const annotationId = Number(document.getElementById('annotation_id').textContent);
    $.ajax(Routes.annotation_path(annotationId), {
      type: 'DELETE',
      dataType: 'json',
      data: {
        annotationId: annotationId
      },
      success: function() {
        annotationManager.updateAnnotations(annotationsToggle.getValue(), null);
        $('#annotation-close-button').click();
      }
    });
  });

  // Event handler for interactive area activation button
  iaButton.addEventListener('click', function() {
    if (iaButton.dataset.status === 'true') {
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
  
  // if videometadata have been loaded, set up video length
  video.addEventListener('loadedmetadata', function() {
    const maxTime = document.getElementById('max-time');
    maxTime.innerHTML = thymeUtility.secondsToTime(video.duration);
    if (video.dataset.time != null) {
      const time = video.dataset.time;
      video.currentTime = time;
    }
  });

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
  thymeKeyShortcuts.addPlayerShortcuts();
});