class AnnotationsToggle extends Button  {
  constructor() {
    super('annotations-toggle-check');
    this.elementJQ = $('#annotations-toggle-check');
    this.div = $('#annotations-toggle');
  }

  add() {
    const toggle = this;
    const toggleJQ = this.elementJQ;

    /* User is teacher/editor for the given medium and visible_for_teacher ist activated?
       -> add toggle annotations button */
    $.ajax(Routes.check_annotation_visibility_path(thymeAttributes.mediumId), {
      type: 'GET',
      dataType: 'json',
      success: function(isPermitted) {
        if (isPermitted) {
          toggle.show();
          toggle.element.addEventListener('click', function() {
            Annotation.updateAnnotations(toggleJQ.is(":checked"));
          });
          // When loading the player, the toggle is set to "true" by default,
          // so we have to trigger updateAnnotations() manually once.
          Annotation.updateAnnotations(toggleJQ.is(":checked"));
        }
      }
    });

  }

  /*
    Auxiliary method
  */
  show() {
    $('#volume-controls').css('left', '66%');
    $('#speed-control').css('left', '77%');
    $('#emergency-button').css('left', '86%');
    thymeAttributes.hideControlBarThreshold.x = 960;
    this.div.show();
    //updateControlBarType(); TODO
  }
}
