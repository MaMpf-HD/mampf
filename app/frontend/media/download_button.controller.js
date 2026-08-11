import { Controller } from "@hotwired/stimulus";

const MOBILE_PLATFORM = /iPad|iPhone|Android/;

/**
 * Keeps a download button off mobile devices, the rule that used to live in
 * courses.coffee. Which device it is decides this, not how wide the window is.
 */
export default class extends Controller {
  connect() {
    if (MOBILE_PLATFORM.test(navigator.platform || "")) {
      this.element.classList.add("d-none");
    }
  }
}
