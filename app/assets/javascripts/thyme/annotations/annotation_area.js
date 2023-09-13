/**
  This class helps to represent the annotation area in java script.
*/
class AnnotationArea {

  /*
    fancyStyle = If true, all buttons are shown, if false, only previous, goto and next are shown.
   */
  constructor(fancyStyle, colorFunc) {
    this.isActive       = false;
    this.onShow         = null; // a function triggered when the modal is shown
    this.onHide         = null; // a function triggered when the modal is hidden
    this.colorFunc      = colorFunc;
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
    $(this.caption).show();
    this.isActive = true;
    if (this.onShow != null) {
      this.onShow();
    }
  }

  /*
    Hide the annotation area.
   */
  hide() {
    $(this.caption).hide();
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
    thymeAttributes.activeAnnotationId = annotation.id;
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
      for (let i = 0; i < annotations.length; i++) {
        if (i != 0 && annotations[i] === annotation) {
          area.update(annotations[i - 1]);
        }
      }
    });
  }

  #updateNextButton(annotation) {
    const annotations = thymeAttributes.annotations;
    const area = this; // need a reference inside the listener scope!
    this.nextButton.off('click');
    this.nextButton.on('click', function() {
      for (let i = 0; i < annotations.length; i++) {
        if (i != annotations.length - 1 && annotations[i] === annotation) {
          area.update(annotations[i + 1]);
        }
      }
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
      thymeAttributes.activeAnnotationId = undefined;
      area.hide();
    });
  }

}