class AnnotationCategoryToggle extends Button  {

  /*
     element = A reference on the element (via document.getElementByID()).
    category = The name of the category this toggle triggers.
     heatmap = The heatmap that will be updated depending on the value of the toggle.
   */
  constructor(element, category, heatmap) {
    super(element);
    this.category = category;
    this.heatmap = heatmap;
  }

  add() {
    const toggle = this;
    const category = this.category;
    const check = document.getElementById(this.element.id + '-check');
    const heatmap = this.heatmap;

    check.addEventListener('click', function() {
      if (toggle.getValue() === true) {
        heatmap.addCategory(category);
        thymeAttributes.annotationManager.updateAnnotations(true);
        heatmap.draw();
      } else {
        heatmap.removeCategory(category);
        thymeAttributes.annotationManager.updateAnnotations(true);
        heatmap.draw();
      }
    });
  }

  getValue() {
    const checkJQ = $('#' + this.element.id + '-check');
    return checkJQ.is(":checked");
  }

}