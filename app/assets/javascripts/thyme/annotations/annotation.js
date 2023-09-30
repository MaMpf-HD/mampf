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
    const markerStr = '<span id="marker-' + this.id + '">' +
                        '<svg width="15" height="20">' +
                        '<polygon points="' + polygonPoints + '"' +
                          'style="fill:' + color + ';' +
                          'stroke:' + strokeColor + ';' +
                          'stroke-width:' + strokeWidth + ';' +
                          'fill-rule:evenodd;"/>' +
                        '</svg>' +
                      '</span>';
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
    Returns a string with the correct translation of the category and subtext of this annotation.
  */
  categoryLocale() {
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
      case "argument":
        s = document.getElementById('annotation-locales').dataset.argument;
        break;
      case "strategy":
        s = document.getElementById('annotation-locales').dataset.strategy;
    }
    return c + " (" + s + ")";
  }
  
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
