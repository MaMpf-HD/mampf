import { Controller } from "@hotwired/stimulus";

/**
 * Shows the first lines of the lecturer's introduction, so that what is due
 * stays near the top of the page, and the rest on request. The toggle only
 * appears when there is more to show.
 */
export default class extends Controller {
  static targets = ["text", "toggle"];
  static values = { moreLabel: String, lessLabel: String };

  connect() {
    this.measure = this.measure.bind(this);
    this.observer = new ResizeObserver(this.measure);
    this.observer.observe(this.textTarget);
    this.measure();
  }

  disconnect() {
    this.observer.disconnect();
  }

  // Measured again whenever the text changes size: loaded through the
  // sidebar's frame, the text is laid out before the stylesheet that clips it.
  measure() {
    if (this.element.classList.contains("lecture-home-intro--expanded")) return;

    const clipped = this.textTarget.scrollHeight > this.textTarget.clientHeight + 1;
    this.toggleTarget.hidden = !clipped;
  }

  toggle() {
    const expanded = this.element.classList.toggle("lecture-home-intro--expanded");
    this.toggleTarget.textContent = expanded ? this.lessLabelValue : this.moreLabelValue;
    this.toggleTarget.setAttribute("aria-expanded", expanded.toString());
  }
}
