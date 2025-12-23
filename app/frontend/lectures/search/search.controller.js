import { Controller } from "@hotwired/stimulus";

/**
 * Controller that loads all lectures when the user scrolls to the bottom of the
 * page.
 */
export default class extends Controller {
  static targets = ["form"];

  connect() {
    this.observer = new IntersectionObserver((entries) => {
      if (this.loaded) return;

      entries.forEach((entry) => {
        if (!this.loaded && entry.isIntersecting) {
          this.search();
          this.loaded = true;
        }
      });
    },
    {
      root: null,
      threshold: 0.1,
    },
    );

    this.observer.observe(this.element);
  }

  disconnect() {
    if (this.observer) {
      this.observer.disconnect();
    }
  }

  /**
   * Triggers a search when the user types in the search field.
   *
   * We use a small delay to avoid too many requests.
   */
  search() {
    clearTimeout(this.timeout);
    this.timeout = setTimeout(() => {
      this.element.requestSubmit();
    }, 200);
  }
}
