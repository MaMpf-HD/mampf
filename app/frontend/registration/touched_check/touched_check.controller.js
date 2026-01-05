import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  connect() {
    this.element.dataset.touched = "false";
    this.update(false);
  }

  mark() {
    this.element.dataset.touched = "true";
    this.update(true);
  }

  reset() {
    this.element.dataset.touched = "false";
    this.update(false);
  }

  update(status) {
    if (status === true)
      document.querySelector("[data-requires-touch-display]").classList.remove("d-none");
    else
      document.querySelector("[data-requires-touch-display]").classList.add("d-none");
  }
}
