import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["input", "editor", "toggle"];

  toggle() {
    const isOpen = !this.editorTarget.classList.contains("d-none");

    if (isOpen) {
      this.close();
    } else {
      this.open();
    }
  }

  open() {
    this.editorTarget.classList.remove("d-none");
    this.toggleTarget.setAttribute("aria-expanded", "true");

    if (this.hasInputTarget) {
      this.inputTarget.focus();
      this.inputTarget.select();
    }
  }

  close() {
    this.editorTarget.classList.add("d-none");
    this.toggleTarget.setAttribute("aria-expanded", "false");
  }
}
