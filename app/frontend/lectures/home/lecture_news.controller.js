import { Controller } from "@hotwired/stimulus";

/**
 * Takes an announcement off the lecture home page once it is marked as read,
 * and the whole section once nothing is left in it. The request itself goes
 * out through the link.
 */
export default class extends Controller {
  static targets = ["row"];

  dismiss(event) {
    event.currentTarget.closest("[data-lecture-news-target='row']")?.remove();
    if (!this.hasRowTarget) this.element.remove();
  }
}
