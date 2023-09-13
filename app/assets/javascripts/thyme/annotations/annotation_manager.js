/**
 * This class provides methods that help to manage all annotations in a thyme player.
 */
class AnnotationManager {

  /*
          colorFunc = A function which takes an annotation and gives
                      back a color for the corresponding marker.

    strokeColorFunc = A function which takes an annotation and gives
                      back a color for the stroke of the corresponding marker.

           sizeFunc = A function which takes an annotation and returns
                      a boolean that is true if and only if the marker
                      corresponding to the annotation should be big.

            onClick = A function that takes an annotation as argument and
                      which is triggered when the corresponding marker is
                      clicked.

           onUpdate = A function that is triggered when the annotations
                      have been updated.

            isValid = A function that takes an annotation as argument and
                      returns a boolean. If and only if it returns true,
                      the given annotation is viualized by this annotation
                      manager.
   */
  constructor(colorFunc, strokeColorFunc, sizeFunc, onClick, onUpdate, isValid) {
    this.colorFunc = colorFunc;
    this.strokeColorFunc = strokeColorFunc;
    this.sizeFunc = sizeFunc;
    this.onClick = onClick;
    this.onUpdate = onUpdate;
    this.isValid = isValid;
  }



  /*
    Updates the markers on the timeline, i.e. the visual represention of the annotations.
    This method is e.g. used for rearranging the markers when the window is being resized.
    Don't mix up with updateAnnotatons() which sends an AJAX request and checks for changes
    in the database.
  */
  updateMarkers() {
    const annotationManager = this;
    $('#' + thymeAttributes.markerBarId).empty();
    AnnotationManager.sortAnnotations();
    for (const a of thymeAttributes.annotations) {
      if (this.isValid(a)) {
        function onClick() {
          annotationManager.onClick(a);
        }
        if (this.sizeFunc !== null && this.sizeFunc(a) === true) {
          a.createBigMarker(this.colorFunc(a), this.strokeColorFunc(a), onClick);
        } else {
          a.createMarker(this.colorFunc(a), this.strokeColorFunc(a), onClick);
        }
      }
    }
    // call additional function that is individual for each player
    this.onUpdate();
  }

  /*
    Sends a AJAX request which returns all the annotations for the given medium.
    This method is e.g. used when a new annotation is being created.
    Don't mix up with updateMarkers() which just updates the position of the markers!

    onSucess = A function that is triggered when the annotations have been
               successfully updated.
  */
  updateAnnotations() {
    const annotationManager = this;
    $.ajax(Routes.update_annotations_path(), {
      type: 'GET',
      dataType: 'json',
      data: {
        mediumId: thymeAttributes.mediumId,
      },
      success: function(annots) {
        // update the annotation field in thymeAttributes
        thymeAttributes.annotations = [];
        if (annots === null) {
          return;
        }
        for (let a of annots) {
          thymeAttributes.annotations.push(new Annotation(a));
        }
        // update visual representation on the seek bar
        annotationManager.updateMarkers();
      }
    });
  }

  /* sorts all annotations according to their timestamp */
  static sortAnnotations() {
    if (thymeAttributes.annotations === null) {
      return;
    }
    thymeAttributes.annotations.sort(function(ann1, ann2) {
      return ann1.seconds - ann2.seconds;
    });
  }

  /*
    Finds the annotation with the given ID in thymeAttributes.annotations.
    Returns null if it doesn't exist.
   */
  static find(id) {
    if (thymeAttributes.annotations == null) {
      return null;
    }
    for (let a of thymeAttributes.annotations) {
      if (a.id === id) {
        return a;
      }
    }
    return null;
  }

}