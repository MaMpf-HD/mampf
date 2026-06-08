import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["inner"];

  connect() {
    this.updateFades();
    this.innerTarget.addEventListener("scroll", this.updateFades.bind(this));

    this.resizeObserver = new ResizeObserver(this.updateFades.bind(this));
    this.resizeObserver.observe(this.innerTarget);
  }

  disconnect() {
    this.innerTarget.removeEventListener("scroll", this.updateFades.bind(this));
    this.resizeObserver?.disconnect();
  }

  updateFades() {
    const { scrollLeft, scrollWidth, clientWidth } = this.innerTarget;
    const hasOverflow = scrollWidth > clientWidth + 5;

    if (hasOverflow) {
      this.innerTarget.setAttribute("data-overflowing", "");
    }
    else {
      this.innerTarget.removeAttribute("data-overflowing");
    }

    this.element.style.setProperty("--fade-left", hasOverflow && scrollLeft > 0 ? "1" : "0");
    this.element.style.setProperty("--fade-right", hasOverflow && scrollLeft + clientWidth < scrollWidth - 5 ? "1" : "0");
  }
}
