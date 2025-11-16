import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["min", "max"];

  connect() {
    this.validateMinMax = this.validateMinMax.bind(this);
    this.minTarget.addEventListener("input", this.validateMinMax);
    this.maxTarget.addEventListener("input", this.validateMinMax);
  }

  validateMinMax() {
    const minValue = parseFloat(this.minTarget.value);
    const maxValue = parseFloat(this.maxTarget.value);

    if (this.minTarget.value && this.maxTarget.value) {
      if (minValue >= maxValue) {
        this.minTarget.setCustomValidity("Minimum value must be less than maximum");
        this.maxTarget.setCustomValidity("Maximum value must be greater than minimum");
      }
      else {
        this.minTarget.setCustomValidity("");
        this.maxTarget.setCustomValidity("");
      }
    }
    else {
      this.minTarget.setCustomValidity("");
      this.maxTarget.setCustomValidity("");
    }
  }
}
