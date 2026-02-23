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
    try {
      const ele = document.querySelector("[data-requires-touch-display]");
      if (!ele) return;

      if (status === true)
        ele.classList.remove("d-none");
      else
        ele.classList.add("d-none");
    }
    catch { /* Element might not exist, ignore */ }
  }
}
