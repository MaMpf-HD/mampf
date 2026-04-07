import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["input"];

  toggle() {
    if (this.element.open && this.hasInputTarget) {
      this.inputTarget.focus();
      this.inputTarget.select();
    }
  }

  close() {
    this.element.removeAttribute("open");
  }
}
