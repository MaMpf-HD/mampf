import { Controller } from "@hotwired/stimulus";

/** Puts the cursor in the title field when the new-vignette dialog opens. */
export default class extends Controller {
  static targets = ["field"];

  connect() {
    this.focusField = () => this.fieldTarget.focus();
    this.element.addEventListener("shown.bs.modal", this.focusField);
  }

  disconnect() {
    this.element.removeEventListener("shown.bs.modal", this.focusField);
  }
}
