import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["inner"];

  connect() {
    this.boundUpdateFades = this.updateFades.bind(this);
    this.updateFades();
    this.innerTarget.addEventListener("scroll", this.boundUpdateFades);

    this.resizeObserver = new ResizeObserver(this.boundUpdateFades);
    this.resizeObserver.observe(this.innerTarget);
  }

  disconnect() {
    this.innerTarget.removeEventListener("scroll", this.boundUpdateFades);
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
    this.element.style.setProperty("--fade-right-offset", `${this.savePinWidth()}px`);
  }

  // The save column sticks to the edge only while its own place lies beyond
  // it; scrolled that far, it sits where it is laid out and pins nothing.
  savePinWidth() {
    const total = this.innerTarget.querySelector("th.total-col");
    const save = this.innerTarget.querySelector("th.save-col");
    if (!total || !save) {
      return 0;
    }
    const { scrollLeft, clientWidth } = this.innerTarget;
    const innerLeft = this.innerTarget.getBoundingClientRect().left;
    const naturalRight = total.getBoundingClientRect().right - innerLeft + scrollLeft + save.offsetWidth;
    return naturalRight > scrollLeft + clientWidth + 1 ? save.offsetWidth : 0;
  }
}
