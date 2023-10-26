/**
  This class helps to represent an annotation in JavaScript.
*/
class Annotation {

  constructor(json) {
    // We only save attributes that are needed in the thyme related JavaScripts!
    this.category = Category.getByName(json.category);
    this.color = json.color;
    this.comment = json.comment;
    this.id = json.id;
    this.seconds = thymeUtility.timestampToSeconds(json.timestamp);
    this.subcategory = Subcategory.getByName(json.subcategory);
    this.belongsToCurrentUser = json.belongs_to_current_user;
  }



  /*
   * AUXILIARY METHODS
   */

  /*
    Create normal marker.

          color = Color of the marker.
    strokeColor = Color of the border of the marker.
        onClick = A function triggered when one clicks on the marker.
   */
  createMarker(color, strokeColor, onClick) {
    const polygonPoints = "1,5 9,5 5,14";
    const strokeWidth = 1;
    this.#create(color, polygonPoints, strokeWidth, strokeColor, onClick);
  }

  /*
    Create big marker with customizable border color.
    (Used e.g. for big mistake markers in the feedback player.)
    
          color = Color of the marker.
    strokeColor = Color of the border of the marker.
        onClick = A function triggered when one clicks on the marker.
   */
  createBigMarker(color, strokeColor, onClick) {
    const polygonPoints = "1,1 9,1 5,14";
    const strokeWidth = 1.5;
    this.#create(color, polygonPoints, strokeWidth, strokeColor, onClick);
  }

  /*
    An auxiliary method, only used for a better structure of createMarker() and createBigMarker()!
   */
  #create(color, polygonPoints, strokeWidth, strokeColor, onClick) {
    // HTML for the marker
    const markerStr = `<span id="marker-${this.id}">
                        <svg width="15" height="20">
                        <polygon points="${polygonPoints}"
                          style="fill:${color};
                          stroke:${strokeColor};
                          stroke-width:${strokeWidth};
                          fill-rule:evenodd;"/>
                        </svg>' +
                      </span>`;
    $('#' + thymeAttributes.markerBarId).append(markerStr);

    // positioning of the marker
    const marker = $('#marker-' + this.id);
    const size = thymeAttributes.seekBar.element.clientWidth - 15;
    const ratio = this.seconds / thymeAttributes.video.duration;
    const offset = marker.parent().offset().left + ratio * size + 3;
    marker.offset({ left: offset });

    // click listener for the marker
    marker.on('click', function() {
      onClick();
    });
  }

  /*
    Returns a string with the correct translation of the category and subcategory of this annotation.
  */
  categoryLocale() {
    const c = this.category;
    const s = this.subcategory;
    return s == null ? c.locale() : c.locale() + " (" + s.locale() + ")";
  }

  /*
   * Returns true if the given annotation is the last annotation
   * in thymeAttributes.annotations
   */
  isFirst() {
    return this == thymeAttributes.annotations[0];
  }

  /*
   * Returns true if the given annotation is the last annotation
   * in thymeAttributes.annotations
   */
  isLast() {
    return this == thymeAttributes.annotations[thymeAttributes.annotations.length - 1];
  }

}
