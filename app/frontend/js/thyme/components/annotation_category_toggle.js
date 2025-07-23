import { Component } from "~/js/thyme/components/component";

export class AnnotationCategoryToggle extends Component {
  /*
     element = A reference on the HTML component (via document.getElementByID()).
    category = The category which this toggle triggers.
     heatmap = The heatmap that will be updated depending on the value of the toggle.
   */
  constructor(category, heatmap) {
    const id = AnnotationCategoryToggle.categoryToElementId(category);
    super(id);
    this.category = category;
    this.heatmap = heatmap;
  }

  static categoryToElementId(category) {
    return `annotation-category-${category.name}-switch`;
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

  static isChecked(category) {
    const id = AnnotationCategoryToggle.categoryToElementId(category);
    return document.getElementById(id).checked;
  }
}
