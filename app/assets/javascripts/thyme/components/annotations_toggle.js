// eslint-disable-next-line no-unused-vars
class AnnotationsToggle extends Component {
  constructor(element) {
    super(element);
    this.id = element;
    this.check = document.getElementById(this.id + "-check");
    this.$check = $("#" + this.id + "-check");
    this.div = $("#" + this.id);
    this.flag = false;
  }

  add() {
    if (this.flag || !thymeAttributes.annotationFeatureActive) {
      return;
    }

    this.flag = true; // <- only run the following part of the code once
    const toggle = this;

    /* User is teacher/editor for the given medium and visible_for_teacher ist activated?
       -> add toggle annotations button */
    $.ajax(Routes.check_annotation_visibility_path(thymeAttributes.mediumId), {
      type: "GET",
      dataType: "json",
      success: function (isPermitted) {
        if (!isPermitted) {
          return;
        }
        for (const annotation of thymeAttributes.annotations) {
          // Only show toggle if there is at least one foreign annotation
          if (!annotation.belongsToCurrentUser) {
            toggle.show();
            toggle.element.addEventListener("click", function () {
              thymeAttributes.annotationManager.updateAnnotations();
            });
            // When loading the player, the toggle is set to "true" by default,
            // so we have to trigger updateAnnotations() manually once.
            thymeAttributes.annotationManager.updateAnnotations();
          }
        }
      },
    });
  }

  installListener() {
    this.element.addEventListener("click", function () {
      thymeAttributes.annotationManager.updateAnnotations();
    });
  }

  /*
    Returns true if the toggle's value is true and false otherwise.
   */
  getValue() {
    return this.$check.is(":checked");
  }

  /*
    Auxiliary method
  */
  show() {
    $("#volume-controls").css("left", "66%");
    $("#speed-control").css("left", "77%");
    $("#annotation-button").css("left", "86%");
    thymeAttributes.hideControlBarThreshold.x = 960;
    this.div.show();
  }
}
