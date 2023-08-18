// a boolean that helps to deactivate all key listeners
// for the time the annotation modal opens and the user
// has to write text into the command box
lockKeyListeners = false;

// when callig the updateMarkersF() method this will be used to save an
// array containing all annotations
annotations = null;

// helps to find the annotation that is currently shown in the
// annotation area
activeAnnotationId = 0;

annotationIndex = function(annotation) {
  for (let i = 0; i < annotations.length; i++) {
    if (annotations[i].id == annotation.id) {
      return i;
    }
  }
};

// returns a certain color for every annotation with respect to the annotations
// category (in the feedback view this gives more information than the original color).
annotationColor = function(cat) {
  switch (cat) {
    case "note":
      return "#44ee11"; //green
    case "content":
      return "#eeee00"; //yellow
    case "mistake":
      return "#ff0000"; //red
    case "presentation":
      return "#ff9933"; //orange
  }
};

// returns a color for the heatmap with respect to the annotation types that are shown.
heatmapColor = function(colors) {
  return colorMixer(colors);
};

// set up everything: read out track data and initialize html elements
setupHypervideoF = function() {
  var video = $('#video').get(0);
  if (video == null) {
    return;
  }
  document.body.style.backgroundColor = 'black';
};

$(document).on('turbolinks:load', function() {
  var thymeContainer = document.getElementById('thyme-feedback');
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
  var plusTenButton = document.getElementById('plus-ten');
  var minusTenButton = document.getElementById('minus-ten');
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
  // below-area
  var toggleNoteAnnotations = document.getElementById('toggle-note-annotations-check');
  var toggleContentAnnotations = document.getElementById('toggle-content-annotations-check');
  var toggleMistakeAnnotations = document.getElementById('toggle-mistake-annotations-check');
  var togglePresentationAnnotations = document.getElementById('toggle-presentation-annotations-check');
  // set seek bar to 0 and volume bar to 1
  seekBar.value = 0;
  volumeBar.value = 1;

  // resizes the thyme container to the window dimensions
  resizeContainer = function() {
    var height = $(window).height();
    var width = Math.floor(video.videoWidth * $(window).height() / video.videoHeight);
    if (width > $(window).width()) {
      var shrink = $(window).width() / width;
      height = Math.floor(height * shrink);
      width = $(window).width();
    }
    var top = Math.floor(0.5 * ($(window).height() - height));
    var left = Math.floor(0.5 * ($(window).width() - width));
    $('#thyme-feedback').css('height', height + 'px');
    $('#thyme-feedback').css('width', width + 'px');
    $('#thyme-feedback').css('top', top + 'px');
    $('#thyme-feedback').css('left', left + 'px');
    if (annotations == null) {
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
    var time = video.duration * seekBar.value / 100;
    video.currentTime = time;
  });

  // Update the seek bar as the video plays
  // uses a gradient for seekbar video time visualization
  video.addEventListener('timeupdate', function() {
    var value = 100 / video.duration * video.currentTime;
    seekBar.value = value;
    seekBar.style.backgroundImage = 'linear-gradient(to right,' +
    ' #2497E3, #2497E3 ' + value + '%, #ffffff ' + value + '%, #ffffff)';
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
    volumeBar.style.backgroundImage = 'linear-gradient(to right,' + ' #2497E3, #2497E3 ' + value * 100 + '%, #ffffff ' + value * 100 + '%, #ffffff)';
  });

  video.addEventListener('click', function() {
    if (video.paused == true) {
      video.play();
    } else {
      video.pause();
    }
    showControlBar();
  });

  // thyme can be used by keyboard as well
  // Arrow up - next chapter
  // Arrow down - previous chapter
  // Arrow right - plus ten seconds
  // Arrow left - minus ten seconds
  // Page up - volume up
  // Page down - volume down
  // m - mute
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
    } else if (key == 'PageUp') {
      video.volume = Math.min(video.volume + 0.1, 1);
    } else if (key == 'PageDown') {
      video.volume = Math.max(video.volume - 0.1, 0);
    } else if (key == 'm') {
      $(muteButton).trigger('click');
    }
  });

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
    var mediumId = thyme.dataset.medium;
    $.ajax(Routes.update_markers_path(), {
      type: 'GET',
      dataType: 'json',
      data: {
        toggled: true,
        mediumId: mediumId
      },
      success: function(annots) {
        annotations = annots;
        if (annotations == null) {
          return;
        }
        rearrangeMarkersF();
        heatmap();
      }
    });
  };

  rearrangeMarkersF = function() {
    $('#feedback-markers').empty();
    sortAnnotations(annotations);
    for (const a of annotations) {
      if (validAnnotation(a) == true) {
        createMarkerF(a);
      }
    }
    heatmap();
  };

  // an auxiliary method for "updateMarkersF()" creating a single marker
  createMarkerF = function(annotation) {
    // create marker
    var polygonPoints, strokeColor, strokeWidth;
    if (annotation.category == "mistake") {
      polygonPoints = "1,1 9,1 5,14";
      strokeWidth = 1.5;
      strokeColor = "darkred";
    } else {
      polygonPoints = "1,5 9,5 5,14";
      strokeWidth = 1;
      strokeColor = "black";
    }
    var markerStr = '<span id="marker-' + annotation.id + '">' +
                      '<svg width="15" height="20">' +
                      '<polygon points="' + polygonPoints + '"' +
                        'style="fill:' + annotationColor(annotation.category) + ';' +
                        'stroke:' + strokeColor + ';' +
                        'stroke-width:' + strokeWidth + ';' +
                        'fill-rule:evenodd;"/>' +
                    '</svg></span>'
    $('#feedback-markers').append(markerStr);
    // set the correct position for the marker
    var marker = $('#marker-' + annotation.id);
    var size = seekBar.clientWidth - 15;
    var ratio = timestampToMillis(annotation.timestamp) / video.duration;
    var offset = marker.parent().offset().left + ratio * size + 3;
    marker.offset({ left: offset });
    marker.on('click', function() {
      updateAnnotationAreaF(annotation);
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

  updateAnnotationAreaF = function(annotation) {
    var activeAnnotationId = annotation.id;
    var head = categoryLocale(annotation.category, annotation.subtext);
    var comment = annotation.comment.replaceAll('\n', '<br>');
    var headColor = lightenUp(annotationColor(annotation.category), 2);
    var backgroundColor = lightenUp(annotationColor(annotation.category), 3);
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
    // previous annotation listener
    $('#annotation-previous-button').on('click', function() {
      for (var i = 0; i < annotations.length; i++) {
        if (i != 0 && annotations[i] == annotation) {
          updateAnnotationAreaF(annotations[i - 1])
        }
      }
    });
    // next annotation Listener
    $('#annotation-next-button').on('click', function() {
      for (var i = 0; i < annotations.length; i++) {
        if (i != annotations.length - 1 && annotations[i] == annotation) {
          updateAnnotationAreaF(annotations[i + 1])
        }
      }
    });
    // goto listener
    $('#annotation-goto-button').on('click', function() {
      video.currentTime = timestampToMillis(annotation.timestamp);
    });
    // LaTex
    renderLatex(document.getElementById('annotation-comment'));
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
    if (annotations == null) {
      return;
    }
    $('#heatmap').empty();

    //
    // variable definitions
    //
    var radius = 10; // total distance from a single peak's maximum to it's minimum
    var width = seekBar.clientWidth + 2 * radius - 35; // width of the video timeline
    var maxHeight = video.clientHeight / 4; // the peaks of the graph should not extend maxHeight
    /* An array for each pixel on the timeline. The indices of this array should be thought
       of the x-axis of the heatmap's graph, while its entries should be thought of its
       values on the y-axis. */
    var pixels = new Array(width + 2 * radius + 1).fill(0);
    /* amplitude should be calculated with respect to all annotations
       (even those which are not shown). Otherwise the peaks increase
       when turning off certain annotations because the graph has to be
       normed. Therefore we need this additional "pixelsAll" array. */
    var pixelsAll = new Array(width + 2 * radius + 1).fill(0);
    /* for any visible annotation, this array contains its color (needed for the calculation
       of the heatmap color) */
    var colors = [];

    //
    // data calculation
    //
    for (const a of annotations) {
      var valid = validAnnotation(a) && a.category !== "mistake"; // <- don't include mistake annotations
      if (valid == true) {
        colors.push(annotationColor(a.category));
      }
      var time = timestampToMillis(a.timestamp);
      var position = Math.round(width * (time / video.duration));
      for (let x = position - radius; x <= position + radius; x++) {
        y = sinX(x, position, radius);
        pixelsAll[x + radius] += y;
        if (valid == true) {
          pixels[x + radius] += y;
        }
      }
    }
    var maxValue = Math.max.apply(Math, pixelsAll);
    var amplitude = maxHeight * (1 / maxValue);

    //
    // draw heatmap
    //
    var pointsStr = "0," + maxHeight + " ";
    for (let x = 0; x < pixels.length; x++) {
      pointsStr += x + "," + (maxHeight - amplitude * pixels[x]) + " ";
    }
    pointsStr += "" + width + "," + maxHeight;
    heatmapStr = '<svg width=' + (width + 35) + ' height="' + maxHeight + '">' +
                   '<polyline points="' + pointsStr + '"' +
                     'style="fill:' + heatmapColor(colors) + ';' +
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