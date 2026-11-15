import { Controller } from "@hotwired/stimulus";

/**
 * Shows another image while the pointer is over an image or an image button.
 *
 * Usage:
 *   <img src="star.png"
 *        data-controller="hover-image"
 *        data-hover-image-src-value="star_hover.png"
 *        data-action="mouseover->hover-image#swap mouseout->hover-image#restore">
 *
 * Turbo may cache the page while the pointer is over the image. The image
 * goes back first, so that the cached page does not start out with the
 * other one as its own.
 */
export default class extends Controller {
  static values = { src: String };

  connect() {
    this.restingSrc = this.element.getAttribute("src");
    this.restoreBeforeCache = () => this.restore();
    document.addEventListener("turbo:before-cache", this.restoreBeforeCache);
  }

  disconnect() {
    document.removeEventListener("turbo:before-cache", this.restoreBeforeCache);
  }

  swap() {
    this.element.src = this.srcValue;
  }

  restore() {
    this.element.src = this.restingSrc;
  }
}
