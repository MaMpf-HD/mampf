class AnnotationCategoryToggle extends Component {

  /*
     element = A reference on the HTML component (via document.getElementByID()).
    category = The category which this toggle triggers.
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
    if (heatmap != null) {
      heatmap.addCategory(category); // add category when adding the button
    }

    check.addEventListener('click', function() {
      thymeAttributes.annotationManager.updateAnnotations();
      if (heatmap != null) {
        if (toggle.getValue() === true) {
          heatmap.addCategory(category);
        } else {
          heatmap.removeCategory(category);
        }
        heatmap.draw();
      }
    });
  }

  getValue() {
    const checkJQ = $('#' + this.element.id + '-check');
    return checkJQ.is(":checked");
  }

}
