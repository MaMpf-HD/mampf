// eslint-disable-next-line no-unused-vars
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
    const heatmap = this.heatmap;
    if (heatmap) {
      heatmap.addCategory(this.category); // add category when adding the button
    }

    const categoryToggle = this;

    this.element.addEventListener("click", function () {
      thymeAttributes.annotationManager.updateAnnotations();
      if (!heatmap) {
        return;
      }

      if (categoryToggle.isChecked()) {
        heatmap.addCategory(this.category);
      }
      else {
        heatmap.removeCategory(this.category);
      }
      heatmap.draw();
    });
  }

  isChecked() {
    return this.element.checked;
  }
}
