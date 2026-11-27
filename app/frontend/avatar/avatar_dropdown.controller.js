import { Controller } from "@hotwired/stimulus";

/**
 * Keeps the menu open for `data-keep-open` interactions.
 * Focuses the dev-only user search (if present) when the menu opens.
 */
export default class extends Controller {
  connect() {
    this.keepOpen = this.keepOpen.bind(this);
    this.focusSearch = this.focusSearch.bind(this);
    this.element.addEventListener("hide.bs.dropdown", this.keepOpen);
    this.element.addEventListener("shown.bs.dropdown", this.focusSearch);
  }

  disconnect() {
    this.element.removeEventListener("hide.bs.dropdown", this.keepOpen);
    this.element.removeEventListener("shown.bs.dropdown", this.focusSearch);
  }

  keepOpen(event) {
    if (event.clickEvent?.target.closest("[data-keep-open]")) {
      event.preventDefault();
    }
  }

  focusSearch() {
    this.element.querySelector("[data-impersonate-list-target=search]")?.focus();
  }
}
