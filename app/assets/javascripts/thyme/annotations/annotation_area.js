/**
  This class helps to represent the annotation area in java script.
*/
// eslint-disable-next-line no-unused-vars
class AnnotationArea {
  static DISABLED_BUTTON_OPACITY = 0.2;

  /*
    hasFancyStyle = If true, all buttons are shown, if false,
                    only previous, goto and next are shown.

        colorFunc = A function for colorizing the annotation area
                    which takes an annotation as argument and gives
                    back a color.

          onClose = A function that is executed when closing the
                    annotation area.

          isValid = A function which takes an annotation as argument
                    and returns true, if and only if the annotation is
                    "valid", i.e. should be visualized in the annotation
                    area. (This is needed to skip unwanted annotations in
                    the previous/next button listeners.)
   */
  constructor(hasFancyStyle, colorFunc, onClose, isValid) {
    this.isActive = false;
    this.annotation = null; // the current annotation
    this.colorFunc = colorFunc;
    this.onClose = onClose;
    this.isValid = isValid;
    this.hasFancyStyle = hasFancyStyle;

    this.caption = $("#annotation-caption");
    this.infoBar = $("#annotation-infobar");
    this.commentField = $("#annotation-comment");
    this.previousButton = $("#annotation-previous-button");
    this.gotoButton = $("#annotation-goto-button");
    this.editButton = $("#annotation-edit-button");
    this.closeButton = $("#annotation-close-button");
    this.nextButton = $("#annotation-next-button");
    this.areaButtonsRegion = $("#annotation-area-buttons");

    this.localesId = "annotation-locales";

    if (!hasFancyStyle) {
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
  }

  /*
    Hide the annotation area.
   */
  hide() {
    this.caption.hide();
    this.isActive = false;
  }

  /*
    Update the annotation area with the content of the given annotation.
   */
  update(annotation) {
    if (!annotation) {
      return;
    }
    const oldId = this.annotation ? this.annotation.id : null;

    this.annotation = annotation;

    // update info and comment field
    this.#updateInfoAndCommentField(annotation, this.colorFunc(annotation));
    // update buttons
    this.#updatePreviousButton(annotation);
    this.#updateNextButton(annotation);
    this.#updateGotoButton(annotation);
    if (this.hasFancyStyle) {
      this.#updateEditButton(annotation);
      this.#updateCloseButton(annotation);
    }
    annotation.updateOpenAnnotationMarker(oldId, annotation.id);

    // render LaTex
    const commentId = this.commentField.attr("id");
    thymeUtility.renderLatex(document.getElementById(commentId));
  }

  /*
    AUXILIARY METHODS
   */
  #updateInfoAndCommentField(annotation, color) {
    const head = annotation.categoryLocale();
    const comment = annotation.comment.replaceAll("\n", "<br>");
    const headColor = thymeUtility.lightenUp(color, 2);
    const backgroundColor = thymeUtility.lightenUp(color, 3);
    this.infoBar.empty().append(head);
    this.infoBar.css("background-color", headColor);
    this.commentField.empty().append(comment);

    // Comment field background gradient
    const colorGradientEnd = thymeUtility.lightenUp(color, 2.5);
    const gradient = `linear-gradient(to bottom, ${backgroundColor} 50%, ${colorGradientEnd} 100%)`;
    this.caption.css("background-image", gradient);

    // Area buttons
    this.areaButtonsRegion.css("background-color", headColor);
  }

  #updatePreviousButton(annotation) {
    const annotations = thymeAttributes.annotations;
    const area = this; // need a reference inside the listener scope!
    this.previousButton.off("click");
    this.previousButton.on("click", function () {
      area.update(area.previousValidAnnotation(annotation));
    });
    if (annotation.isFirst()) {
      this.previousButton.css("opacity", AnnotationArea.DISABLED_BUTTON_OPACITY);
    }
    else {
      this.previousButton.css("opacity", 1);
    }
  }

  #updateNextButton(annotation) {
    const annotations = thymeAttributes.annotations;
    const area = this; // need a reference inside the listener scope!
    this.nextButton.off("click");
    this.nextButton.on("click", function () {
      area.update(area.nextValidAnnotation(annotation));
    });
    if (annotation.isLast()) {
      this.nextButton.css("opacity", AnnotationArea.DISABLED_BUTTON_OPACITY);
    }
    else {
      this.nextButton.css("opacity", 1);
    }
  }

  #updateGotoButton(annotation) {
    this.gotoButton.off("click");
    this.gotoButton.on("click", function () {
      video.currentTime = annotation.seconds;
    });
  }

  #updateEditButton(annotation) {
    const localesId = this.localesId;
    this.editButton.off("click");
    this.editButton.on("click", function () {
      thymeAttributes.video.pause();
      thymeAttributes.lockKeyListeners = true;
      $.ajax(Routes.edit_annotation_path(annotation.id), {
        type: "GET",
        dataType: "script",
        data: {
          annotation_id: annotation.id,
        },
        success: function (permitted) {
          if (permitted === "false") {
            alert(document.getElementById(localesId).dataset.permission);
          }
        },
        error: function (e) {
          console.log(e);
        },
      });
    });
  }

  unmarkCurrentAnnotationAsShown() {
    if (!this.annotation) {
      return;
    }
    this.annotation.markCurrentAnnotationAsNotShown();
  }

  #updateCloseButton(annotation) {
    const close = this.close;
    const area = this; // need a reference inside the listener scope!
    this.closeButton.off("click");
    this.closeButton.on("click", function () {
      area.unmarkCurrentAnnotationAsShown();
      area.annotation = undefined;
      area.hide();
      if (area.onClose != null) {
        area.onClose();
      }
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
