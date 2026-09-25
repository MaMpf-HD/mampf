import { Controller } from "@hotwired/stimulus";

/**
 * Takes an announcement off the lecture home page once the server has marked
 * it as read (rails-ujs sends the link as a remote DELETE and reports success),
 * and the whole section once nothing is left in it, not even a link to older
 * announcements.
 */
export default class extends Controller {
  static targets = ["row", "more"];

  dismiss(event) {
    event.currentTarget.closest("[data-lecture-news-target='row']")?.remove();
    if (!this.hasRowTarget && !this.hasMoreTarget) this.element.remove();
  }
}
