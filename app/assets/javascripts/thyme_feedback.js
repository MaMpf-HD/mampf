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
  // Buttons
  (new PlayButton).add();
  (new MuteButton).add();
  (new PlusTenButton).add();
  (new MinusTenButton).add();
  // Sliders
  (new VolumeBar).add();
  seekBar = new SeekBar();
  seekBar.add();

  // Video
  const video = document.getElementById('video');
  const thyme = document.getElementById('thyme');
  // initialize medium id
  thymeAttributes.mediumId = thyme.dataset.medium;
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
  // reset faders
  video.currentTime = 0;
  video.volume = 1;

  // resizes the thyme container to the window dimensions
  function resizeContainer() {
    resize.resizeContainer(thymeContainer, 1);
    if (thymeAttributes.annotations === null) {
      updateMarkersF();
    } else {
      rearrangeMarkersF();
    }
  };

  setupHypervideoF();
  window.onresize = resizeContainer;
  video.onloadedmetadata = resizeContainer;

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
  function updateMarkersF() {
    $.ajax(Routes.update_markers_path(), {
      type: 'GET',
      dataType: 'json',
      data: {
        toggled: true,
        mediumId: thymeAttributes.mediumId
      },
      success: function(annots) {
        thymeAttributes.annotations = annots;
        if (annots === null) {
          return;
        }
        rearrangeMarkersF();
        (new Heatmap(validCategories())).draw();
      }
    });
  };

  function rearrangeMarkersF() {
    $('#feedback-markers').empty();
    thymeUtility.annotationSort();
    for (const a of thymeAttributes.annotations) {
      if (validAnnotation(a) === true) {
        createMarkerF(a);
      }
    }
    (new Heatmap(validCategories())).draw();
  };

  // an auxiliary method for "updateMarkersF()" creating a single marker
  function createMarkerF(annotation) {
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
    const size = seekBar.element.clientWidth - 15;
    const ratio = thymeUtility.timestampToSeconds(annotation.timestamp) / video.duration;
    const offset = marker.parent().offset().left + ratio * size + 3;
    marker.offset({ left: offset });
    marker.on('click', function() {
      updateAnnotationAreaF(annotation);
    });
  };

  function categoryLocale(category, subtext) {
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

  function updateAnnotationAreaF(annotation) {
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
      video.currentTime = thymeUtility.timestampToSeconds(annotation.timestamp);
    });
    // LaTex
    thymeUtility.renderLatex(document.getElementById('annotation-comment'));
  };

  // Depending on the toggle switches, which are activated, this method checks, if
  // an annotation should be displayed or not.
  function validAnnotation(annotation) {
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

  /*
    This method returns an array containing the names of all categories
    of which the corresponding toggle switch is set to true.
  */
  function validCategories() {
    let array = [];
    if ($('#toggle-mistake-annotations-check').is(":checked")) {
      array.push("mistake");
    }
    if ($('#toggle-presentation-annotations-check').is(":checked")) {
      array.push("presentation");
    }
    if ($('#toggle-content-annotations-check').is(":checked")) {
      array.push("content");
    }
    if ($('#toggle-note-annotations-check').is(":checked")) {
      array.push("note");
    }
    return array;
  }
});