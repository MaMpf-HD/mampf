// set up everything: read out track data and initialize html elements
setupHypervideoF = function() {
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
  const thyme = document.getElementById('thyme');
  // Buttons
  const playButton = document.getElementById('play-pause');
  const muteButton = document.getElementById('mute');
  const plusTenButton = document.getElementById('plus-ten');
  const minusTenButton = document.getElementById('minus-ten');
  // Sliders
  const seekBar = document.getElementById('seek-bar');
  const volumeBar = document.getElementById('volume-bar');
  // Selectors
  const speedSelector = document.getElementById('speed');
  // Time
  const currentTime = document.getElementById('current-time');
  const maxTime = document.getElementById('max-time');
  // ControlBar
  const videoControlBar = document.getElementById('video-controlBar');
  // below-area
  const toggleNoteAnnotations = document.getElementById('toggle-note-annotations-check');
  const toggleContentAnnotations = document.getElementById('toggle-content-annotations-check');
  const toggleMistakeAnnotations = document.getElementById('toggle-mistake-annotations-check');
  const togglePresentationAnnotations = document.getElementById('toggle-presentation-annotations-check');
  // set seek bar to 0 and volume bar to 1
  seekBar.value = 0;
  volumeBar.value = 1;

  // resizes the thyme container to the window dimensions
  resizeContainer = function() {
    let height = $(window).height();
    let width = Math.floor(video.videoWidth * $(window).height() / video.videoHeight);
    if (width > $(window).width()) {
      const shrink = $(window).width() / width;
      height = Math.floor(height * shrink);
      width = $(window).width();
    }
    const top = Math.floor(0.5 * ($(window).height() - height));
    const left = Math.floor(0.5 * ($(window).width() - width));
    $('#thyme-feedback').css('height', height + 'px');
    $('#thyme-feedback').css('width', width + 'px');
    $('#thyme-feedback').css('top', top + 'px');
    $('#thyme-feedback').css('left', left + 'px');
    if (thymeAttributes.annotations === null) {
      updateMarkersF();
    } else {
      rearrangeMarkersF();
    }
  };

  setupHypervideoF();
  window.onresize = resizeContainer;
  video.onloadedmetadata = resizeContainer;

  // Event listener for the play/pause button
  playButton.addEventListener('click', function() {
    if (video.paused === true) {
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
    if (video.muted === false) {
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

  // Event listeners for the seek bar
  seekBar.addEventListener('input', function() {
    const time = video.duration * seekBar.value / 100;
    video.currentTime = time;
  });

  // Update the seek bar as the video plays
  // uses a gradient for seekbar video time visualization
  video.addEventListener('timeupdate', function() {
    const value = 100 / video.duration * video.currentTime;
    seekBar.value = value;
    seekBar.style.backgroundImage = 'linear-gradient(to right,' +
    ' #2497E3, #2497E3 ' + value + '%, #ffffff ' + value + '%, #ffffff)';
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
  volumeBar.addEventListener('input', function() {
    const value = volumeBar.value;
    video.volume = value;
  });

  video.addEventListener('volumechange', function() {
    const value = video.volume;
    volumeBar.value = value;
    volumeBar.style.backgroundImage = 'linear-gradient(to right,' + ' #2497E3, #2497E3 ' + value * 100 + '%, #ffffff ' + value * 100 + '%, #ffffff)';
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
  thymeKey.addGeneralShortcuts();
  thymeKey.addFeedbackShortcuts();

  // Toggles which annotations are shown
  toggleNoteAnnotations.addEventListener('click', function() {
    updateMarkersF();
  });

  toggleContentAnnotations.addEventListener('click', function() {
    updateMarkersF();
  });

  toggleMistakeAnnotations.addEventListener('click', function() {
    updateMarkersF();
  });

  togglePresentationAnnotations.addEventListener('click', function() {
    updateMarkersF();
  });

  // updates the annotation markers
  updateMarkersF = function() {
    const mediumId = thyme.dataset.medium;
    $.ajax(Routes.update_markers_path(), {
      type: 'GET',
      dataType: 'json',
      data: {
        toggled: true,
        mediumId: mediumId
      },
      success: function(annots) {
        thymeAttributes.annotations = annots;
        if (annots === null) {
          return;
        }
        rearrangeMarkersF();
        heatmap();
      }
    });
  };

  rearrangeMarkersF = function() {
    $('#feedback-markers').empty();
    thymeUtility.annotationSort();
    for (const a of thymeAttributes.annotations) {
      if (validAnnotation(a) === true) {
        createMarkerF(a);
      }
    }
    heatmap();
  };

  // an auxiliary method for "updateMarkersF()" creating a single marker
  createMarkerF = function(annotation) {
    // create marker
    let polygonPoints, strokeColor, strokeWidth;
    if (annotation.category === "mistake") {
      polygonPoints = "1,1 9,1 5,14";
      strokeWidth = 1.5;
      strokeColor = "darkred";
    } else {
      polygonPoints = "1,5 9,5 5,14";
      strokeWidth = 1;
      strokeColor = "black";
    }
    const markerStr = '<span id="marker-' + annotation.id + '">' +
                        '<svg width="15" height="20">' +
                        '<polygon points="' + polygonPoints + '"' +
                          'style="fill:' + thymeUtility.annotationColor(annotation.category) + ';' +
                          'stroke:' + strokeColor + ';' +
                          'stroke-width:' + strokeWidth + ';' +
                          'fill-rule:evenodd;"/>' +
                      '</svg></span>'
    $('#feedback-markers').append(markerStr);
    // set the correct position for the marker
    const marker = $('#marker-' + annotation.id);
    const size = seekBar.clientWidth - 15;
    const ratio = thymeUtility.timestampToMillis(annotation.timestamp) / video.duration;
    const offset = marker.parent().offset().left + ratio * size + 3;
    marker.offset({ left: offset });
    marker.on('click', function() {
      updateAnnotationAreaF(annotation);
    });
  };

  categoryLocale = function(category, subtext) {
    let c, s;
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
    if (subtext === null) {
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

  updateAnnotationAreaF = function(annotation) {
    thymeAttributes.activeAnnotationId = annotation.id;
    const head = categoryLocale(annotation.category, annotation.subtext);
    const comment = annotation.comment.replaceAll('\n', '<br>');
    const headColor = thymeUtility.lightenUp(thymeUtility.annotationColor(annotation.category), 2);
    const backgroundColor = thymeUtility.lightenUp(thymeUtility.annotationColor(annotation.category), 3);
    $('#annotation-infobar').empty().append(head);
    $('#annotation-infobar').css('background-color', headColor);
    $('#annotation-infobar').css('text-align', 'center');
    $('#annotation-comment').empty().append(comment);
    $('#annotation-caption').css('background-color', backgroundColor);
    // remove old listeners
    $('#annotation-previous-button').off('click');
    $('#annotation-next-button').off('click');
    $('#annotation-goto-button').off('click');
    $('#annotation-close-button').off('click');
    // shorthand
    const a = thymeAttributes.annotations;
    // previous annotation listener
    $('#annotation-previous-button').on('click', function() {
      for (let i = 0; i < a.length; i++) {
        if (i != 0 && a[i] === annotation) {
          updateAnnotationAreaF(a[i - 1])
        }
      }
    });
    // next annotation Listener
    $('#annotation-next-button').on('click', function() {
      for (let i = 0; i < a.length; i++) {
        if (i != a.length - 1 && a[i] === annotation) {
          updateAnnotationAreaF(a[i + 1])
        }
      }
    });
    // goto listener
    $('#annotation-goto-button').on('click', function() {
      video.currentTime = thymeUtility.timestampToMillis(annotation.timestamp);
    });
    // LaTex
    thymeUtility.renderLatex(document.getElementById('annotation-comment'));
  };

  // Depending on the toggle switches, which are activated, this method checks, if
  // an annotation should be displayed or not.
  validAnnotation = function(annotation) {
    switch (annotation.category) {
      case "note":
        return $('#toggle-note-annotations-check').is(":checked");
      case "content":
        return $('#toggle-content-annotations-check').is(":checked");
      case "mistake":
        return $('#toggle-mistake-annotations-check').is(":checked");
      case "presentation":
        return $('#toggle-presentation-annotations-check').is(":checked");
    }
  };

  heatmap = function() {
    if (thymeAttributes.annotations === null) {
      return;
    }
    $('#heatmap').empty();

    //
    // variable definitions
    //
    const radius = 10; // total distance from a single peak's maximum to it's minimum
    const width = seekBar.clientWidth + 2 * radius - 35; // width of the video timeline
    const maxHeight = video.clientHeight / 4; // the peaks of the graph should not extend maxHeight
    /* An array for each pixel on the timeline. The indices of this array should be thought
       of the x-axis of the heatmap's graph, while its entries should be thought of its
       values on the y-axis. */
    let pixels = new Array(width + 2 * radius + 1).fill(0);
    /* amplitude should be calculated with respect to all annotations
       (even those which are not shown). Otherwise the peaks increase
       when turning off certain annotations because the graph has to be
       normed. Therefore we need this additional "pixelsAll" array. */
    let pixelsAll = new Array(width + 2 * radius + 1).fill(0);
    /* for any visible annotation, this array contains its color (needed for the calculation
       of the heatmap color) */
    let colors = [];

    //
    // data calculation
    //
    for (const a of thymeAttributes.annotations) {
      const valid = validAnnotation(a) && a.category !== "mistake"; // <- don't include mistake annotations
      if (valid === true) {
        colors.push(thymeUtility.annotationColor(a.category));
      }
      const time = thymeUtility.timestampToMillis(a.timestamp);
      const position = Math.round(width * (time / video.duration));
      for (let x = position - radius; x <= position + radius; x++) {
        y = sinX(x, position, radius);
        pixelsAll[x + radius] += y;
        if (valid === true) {
          pixels[x + radius] += y;
        }
      }
    }
    const maxValue = Math.max.apply(Math, pixelsAll);
    const amplitude = maxHeight * (1 / maxValue);

    //
    // draw heatmap
    //
    let pointsStr = "0," + maxHeight + " ";
    for (let x = 0; x < pixels.length; x++) {
      pointsStr += x + "," + (maxHeight - amplitude * pixels[x]) + " ";
    }
    pointsStr += "" + width + "," + maxHeight;
    heatmapStr = '<svg width=' + (width + 35) + ' height="' + maxHeight + '">' +
                   '<polyline points="' + pointsStr + '"' +
                     'style="fill:' + thymeUtility.colorMixer(colors) + ';' +
                     'fill-opacity:0.4;' +
                     'stroke:black;' +
                     'stroke-width:1"/>' +
                 '</svg>';
    $('#heatmap').append(heatmapStr);
    offset = $('#heatmap').parent().offset().left - radius + 79;
    $('#heatmap').offset({ left: offset });
    $('#heatmap').css('top', -maxHeight - 4); // vertical offset
  };

  // A modified sine function for building nice peaks around the marker positions.
  //
  //   x = insert value
  //   position = the position of the maximum value
  //   radius = the distance from a minimum to a maximum of the sine wave
  sinX = function(x, position, radius) {
    return (1 + Math.sin(Math.PI / radius * (x - position) + Math.PI / 2)) / 2;
  };
});