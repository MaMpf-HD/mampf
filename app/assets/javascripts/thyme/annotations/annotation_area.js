/**
  This class helps to represent the annotation area in java script.
*/
class AnnotationArea {

  /*
    fancyStyle = If true, all buttons are shown, if false,
                 only previous, goto and next are shown.

     colorFunc = A function for colorizing the annotation area
                 which takes an annotation as argument and gives
                 back a color.

       isValid = A function which takes an annotation as argument
                 and returns true, if and only if the annotation is
                 "valid", i.e. should be visualized in the annotation
                 area. (This is needed to skip unwanted annotations in
                 the previous/next button listeners.)
   */
  constructor(fancyStyle, colorFunc, isValid) {
    this.isActive       = false;
    this.annotation     = null; // the current annotation
    this.onShow         = null; // a function triggered when the modal is shown
    this.onHide         = null; // a function triggered when the modal is hidden
    this.colorFunc      = colorFunc;
    this.isValid        = isValid;
    this.fancyStyle     = fancyStyle;

    this.caption        = $('#annotation-caption');
    this.inforBar       = $('#annotation-infobar');
    this.commentField   = $('#annotation-comment');
    this.previousButton = $('#annotation-previous-button');
    this.gotoButton     = $('#annotation-goto-button');
    this.editButton     = $('#annotation-edit-button');
    this.closeButton    = $('#annotation-close-button');
    this.nextButton     = $('#annotation-next-button');

    this.localesId      = 'annotation-locales';

    if (fancyStyle === false) {
      this.editButton.hide();
      this.closeButton.hide();
    }
  }



  /*
    Show the annotation area.
  */
  show() {
    this.caption.show();
    this.isActive = true;
    if (this.onShow != null) {
      this.onShow();
    }
  }

  /*
    Hide the annotation area.
   */
  hide() {
    this.caption.hide();
    this.isActive = false;
    if (this.onHide != null) {
      this.onHide();
    }
  }

  /*
    Update the annotation area with the content of the given annotation.
   */
  update(annotation) {
    if (annotation == null) {
      return;
    }
    this.annotation = annotation;
    // update info and comment field
    this.#updateInfoAndCommentField(annotation, this.colorFunc(annotation));
    // update buttons
    this.#updatePreviousButton(annotation);
    this.#updateNextButton(annotation);
    this.#updateGotoButton(annotation);
    if (this.fancyStyle == true) {
      this.#updateEditButton(annotation);
      this.#updateCloseButton(annotation);
    }
    // render LaTex
    const commentId = this.commentField.attr('id');
    thymeUtility.renderLatex(document.getElementById(commentId));
  }



  /*
    AUXILIARY METHODS
   */
  #updateInfoAndCommentField(annotation, color) {
    const head = annotation.categoryLocale();
    const comment = annotation.comment.replaceAll('\n', '<br>');
    const headColor = thymeUtility.lightenUp(color, 2);
    const backgroundColor = thymeUtility.lightenUp(color, 3);
    this.inforBar.empty().append(head);
    this.inforBar.css('background-color', headColor);
    this.inforBar.css('text-align', 'center');
    this.commentField.empty().append(comment);
    this.caption.css('background-color', backgroundColor);
  }

  #updatePreviousButton(annotation) {
    const annotations = thymeAttributes.annotations;
    const area = this; // need a reference inside the listener scope!
    this.previousButton.off('click');
    this.previousButton.on('click', function() {
      area.update(area.previousValidAnnotation(annotation));
    });
  }

  #updateNextButton(annotation) {
    const annotations = thymeAttributes.annotations;
    const area = this; // need a reference inside the listener scope!
    this.nextButton.off('click');
    this.nextButton.on('click', function() {
      area.update(area.nextValidAnnotation(annotation));
    });
  }

  #updateGotoButton(annotation) {
    this.gotoButton.off('click');
    this.gotoButton.on('click', function() {
      video.currentTime = annotation.seconds;
    });
  }

  #updateEditButton(annotation) {
    const localesId = this.localesId;
    this.editButton.off('click');
    this.editButton.on('click', function() {
      thymeAttributes.lockKeyListeners = true;
      $.ajax(Routes.edit_annotation_path(annotation.id), {
        type: 'GET',
        dataType: 'script',
        data: {
          annotationId: annotation.id
        },
        success: function(permitted) {
          if (permitted === "false") {
            alert(document.getElementById(localesId).dataset.permission);
          }
        },
        error: function(e) {
          console.log(e);
        }
      });
    });
  }

  #updateCloseButton(annotation) {
    const close = this.close;
    const area = this; // need a reference inside the listener scope!
    this.closeButton.off('click');
    this.closeButton.on('click', function() {
      area.annotation = undefined;
      area.hide();
    });
  }

  /*
    Returns the first annotation which is valid and which comes
    before the input annotation on the timeline.
    Returns null if no valid annotation before the input annotation
    exists.
   */
  previousValidAnnotation(annotation) {
    const currentId = this.annotation.id;
    const currentIndex = AnnotationManager.findIndex(currentId);
    const annotations = thymeAttributes.annotations;
    for (let i = currentIndex - 1; i >= 0; i--) {
      if (this.isValid(annotations[i])) {
        return annotations[i];
      }
    }
    return null;
  }

  /*
    Returns the first annotation which is valid and which comes
    after the input annotation on the timeline.
    Returns null if no valid annotation after the input annotation
    exists.
   */
  nextValidAnnotation(annotation) {
    const currentId = this.annotation.id;
    const currentIndex = AnnotationManager.findIndex(currentId);
    const annotations = thymeAttributes.annotations;
    for (let i = currentIndex + 1; i < annotations.length; i++) {
      if (this.isValid(annotations[i])) {
        return annotations[i];
      }
    }
    return null;
  }

}