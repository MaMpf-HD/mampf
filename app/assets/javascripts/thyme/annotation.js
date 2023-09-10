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
   * AUXILIARY METHODS 
   */

  /* Returns a fixed color depending only on the category of the annotation. */
  categoryColor() {
    switch (this.category) {
      case "note":
        return "#44ee11"; //green
      case "content":
        return "#eeee00"; //yellow
      case "mistake":
        return "#ff0000"; //red
      case "presentation":
        return "#ff9933"; //orange
    }
  }

  /*
    Create normal marker.

          color = Color of the marker.
    strokeColor = Color of the border of the marker.
   */
  createMarker(color, strokeColor) {
    const polygonPoints = "1,5 9,5 5,14";
    const strokeWidth = 1;
    this.#create(polygonPoints, strokeWidth, strokeColor);
  }

  /*
    Create big marker with customizable border color.
    (Used e.g. for big mistake markers in the feedback player.)
    
          color = Color of the marker.
    strokeColor = Color of the border of the marker.
   */
  createBigMarker(color, strokeColor) {
    const polygonPoints = "1,1 9,1 5,14";
    const strokeWidth = 1.5;
    this.#create(polygonPoints, strokeWidth, strokeColor);
  }

  /*
    An auxiliary method, only used for a better structure of createMarker() and createBigMarker()!
   */
  #create(polygonPoints, strokeWidth, strokeColor) {
    // HTML for the marker
    const markerStr = '<span id="marker-' + this.id + '">' +
                        '<svg width="15" height="20">' +
                        '<polygon points="' + polygonPoints + '"' +
                          'style="fill:' + this.color + ';' +
                          'stroke:' + strokeColor + ';' +
                          'stroke-width:' + strokeWidth + ';' +
                          'fill-rule:evenodd;"/>' +
                        '</svg>' +
                      '</span>';
    $('#' + thymeAttributes.markerBarID).append(markerStr);

    // positioning of the marker
    const marker = $('#marker-' + this.id);
    const size = thymeAttributes.seekBar.element.clientWidth - 15;
    const ratio = this.seconds / thymeAttributes.video.duration;
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