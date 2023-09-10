/**
  This class helps to represent an annotation in JavaScript.
*/
class Annotation {
  constructor(json) {
    // We only save attributes that are needed in the thyme related JavaScripts in the asset pipeline!
    this.category = json.category;
    this.color = json.color;
    this.comment = json.comment;
    this.id = json.id;
    this.seconds = thymeUtility.timestampToSeconds(json.timestamp);
    this.subtext = json.subtext;
  }

  /*
    Shows the information for this annotation in the annotation area.
  */
  updateAnnotationArea() {
    thymeAttributes.activeAnnotationId = this.id;
    const head = this.#categoryLocale();
    const comment = this.comment.replaceAll('\n', '<br>');
    const headColor = thymeUtility.lightenUp(this.color, 2);
    const backgroundColor = thymeUtility.lightenUp(this.color, 3);
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
    // shorthand
    const annotations = thymeAttributes.annotations;
    const a = this;
    // previous annotation listener
    $('#annotation-previous-button').on('click', function() {
      for (let i = 0; i < annotations.length; i++) {
        if (i != 0 && annotations[i] === a) {
          annotations[i - 1].updateAnnotationArea();
        }
      }
    });
    // next annotation Listener
    $('#annotation-next-button').on('click', function() {
      for (let i = 0; i < annotations.length; i++) {
        if (i != annotations.length - 1 && annotations[i] === a) {
          annotations[i + 1].updateAnnotationArea();
        }
      }
    });
    // goto listener
    $('#annotation-goto-button').on('click', function() {
      video.currentTime = a.seconds;
    });
    // edit listener
    $('#annotation-edit-button').on('click', function() {
      thymeAttributes.lockKeyListeners = true;
      $.ajax(Routes.edit_annotation_path(a.id), {
        type: 'GET',
        dataType: 'script',
        data: {
          annotationId: a.id
        },
        success: function(permitted) {
          if (permitted === "false") {
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
      thymeAttributes.activeAnnotationId = 0;
      $('#annotation-caption').hide();
      $('#caption').show();
    });
    // LaTex
    thymeUtility.renderLatex(document.getElementById('annotation-comment'));
  }

  /*
    Updates the markers on the timeline, i.e. the visual represention of the annotations.
    This method is e.g. used for rearranging the markers when the window is being resized.
    Don't mix up with updateAnnotatons() which sends an AJAX request and checks for changes
    in the database.
  */
  static updateMarkers() {
    $('#markers').empty();
    thymeUtility.annotationSort();
    for (const annotation of thymeAttributes.annotations) {
      annotation.#createMarker();
    }
  }

  /*
    Sends a AJAX request which returns all the annotations for the given medium.
    This method is e.g. used when a new annotation is being created.
    Don't mix up with updateMarkers() which just updates the position of the markers!

    "toggle" must be a boolean. If true, teachers see all annotations that have been
    made visible for teachers; otherwise they see only their own.
  */
  static updateAnnotations(toggled) {
    $.ajax(Routes.update_annotations_path(), {
      type: 'GET',
      dataType: 'json',
      data: {
        mediumId: thymeAttributes.mediumId,
        toggled: toggled
      },
      success: function(annots) {
        // update the annotation field in thymeAttributes
        thymeAttributes.annotations = [];
        if (annots === null) {
          return;
        }
        for (const a of annots) {
          thymeAttributes.annotations.push(new Annotation(a));
        }
        // update visual representation on the seek bar
        Annotation.updateMarkers();
        // TODO: update annotation area -> this is player specific
        // and should be done in the player script!
      }
    });
  }



  /*
   * AUXILIARY METHODS 
   */

  /*
    Creates a single marker on the seek bar.
  */
  #createMarker() {
    // HTML for the marker
    const markerStr = '<span id="marker-' + this.id + '">' +
                        '<svg width="15" height="15">' +
                        '<polygon points="1,1 9,1 5,10"' +
                          'style="fill:' + this.color + ';' +
                          'stroke:black;' +
                          'stroke-width:1;' +
                          'fill-rule:evenodd;"/>' +
                        '</svg>' +
                      '</span>';
    $('#markers').append(markerStr);

    // positioning of the marker
    const marker = $('#marker-' + this.id);
    const size = thymeAttributes.seekBar.element.clientWidth - 15;
    const video = document.getElementById('video');
    const ratio = this.seconds / video.duration;
    const offset = marker.parent().offset().left + ratio * size + 3;
    marker.offset({ left: offset });

    // click listener for the marker
    const a = this;
    marker.on('click', function() {
      const iaButton = document.getElementById('ia-active');
      if (iaButton.dataset.status === "false") {
        $(iaButton).trigger('click');
      }
      $('#caption').hide();
      a.updateAnnotationArea();
      $('#annotation-caption').show();
    });
  }

  /*
    Returns a string with the correct translation of the category and subtext of this annotation.
  */
  #categoryLocale() {
    let c, s;
    switch (this.category) {
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
    if (this.subtext === null) {
      return c;
    }
    switch (this.subtext) {
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
  }

}