import { Controller } from "@hotwired/stimulus";

/** Keeps the menu open for `data-keep-open` interactions.
 * Focuses user search after the user switcher expands.
 */
export default class extends Controller {
  connect() {
    this.keepOpen = this.keepOpen.bind(this);
    this.focusSearch = this.focusSearch.bind(this);
    this.element.addEventListener("hide.bs.dropdown", this.keepOpen);
    this.element.addEventListener("shown.bs.collapse", this.focusSearch);
  }

  disconnect() {
    this.element.removeEventListener("hide.bs.dropdown", this.keepOpen);
    this.element.removeEventListener("shown.bs.collapse", this.focusSearch);
  }

  keepOpen(event) {
    if (event.clickEvent?.target.closest("[data-keep-open]")) {
      event.preventDefault();
    }
  }

  focusSearch(event) {
    event.target.querySelector("input[type=text]")?.focus();
  }
}
