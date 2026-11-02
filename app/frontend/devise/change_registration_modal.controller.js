import { Controller } from "@hotwired/stimulus";

// Restores a modal's form to its initial state when the modal is closed
export default class extends Controller {
  static values = { container: String };

  connect() {
    this.initialHTML = this.container?.outerHTML;
    this.reset = this.reset.bind(this);
    this.element.addEventListener("hidden.bs.modal", this.reset);
  }

  disconnect() {
    this.element.removeEventListener("hidden.bs.modal", this.reset);
  }

  reset() {
    if (this.initialHTML && this.container) {
      this.container.outerHTML = this.initialHTML;
    }
  }

  get container() {
    return document.getElementById(this.containerValue);
  }
}
