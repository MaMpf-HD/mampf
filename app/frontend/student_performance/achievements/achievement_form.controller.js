import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["threshold"];

  connect() {
    this.toggle();
  }

  toggle() {
    const select = this.element.querySelector("select[name*='value_type']");
    if (!select) return;

    const isBoolean = select.value === "boolean";
    this.thresholdTarget.style.display = isBoolean ? "none" : "";

    if (isBoolean) {
      const input = this.thresholdTarget.querySelector("input");
      if (input) input.value = "";
    }
  }
}
