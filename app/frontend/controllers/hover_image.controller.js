import { Controller } from "@hotwired/stimulus";

/**
 * Shows another image while the pointer is over an image or an image button.
 *
 * Usage:
 *   <img src="star.png"
 *        data-controller="hover-image"
 *        data-hover-image-src-value="star_hover.png"
 *        data-action="mouseover->hover-image#swap mouseout->hover-image#restore">
 */
export default class extends Controller {
  static values = { src: String };

  connect() {
    this.restingSrc = this.element.getAttribute("src");
  }

  swap() {
    this.element.src = this.srcValue;
  }

  restore() {
    this.element.src = this.restingSrc;
  }
}
