import { Controller } from "@hotwired/stimulus";
import { Collapse } from "bootstrap";

export default class extends Controller {
  static targets = ["content"];

  connect() {
    if (this.hasContentTarget) {
      this.collapse = new Collapse(this.contentTarget, { toggle: false });
    }
  }

  disconnect() {
    if (this.collapse) {
      this.collapse.dispose();
    }
  }

  toggle(event) {
    event.preventDefault();
    if (this.collapse) {
      this.collapse.toggle();
    }
  }
}
