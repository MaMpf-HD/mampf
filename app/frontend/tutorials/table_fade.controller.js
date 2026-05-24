import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["inner"];

  connect() {
    this.updateFades();
    this.innerTarget.addEventListener("scroll", this.updateFades.bind(this));
  }

  disconnect() {
    this.innerTarget.removeEventListener("scroll", this.updateFades.bind(this));
  }

  updateFades() {
    const { scrollLeft, scrollWidth, clientWidth } = this.innerTarget;
    this.element.style.setProperty("--fade-left", scrollLeft > 0 ? "1" : "0");
    this.element.style.setProperty("--fade-right", scrollLeft + clientWidth < scrollWidth ? "1" : "0");
  }
}
