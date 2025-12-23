import { Controller } from "@hotwired/stimulus";
import { addDataToForm } from "~/js/form_helper.js";

/**
 * Controller that loads lectures when the user scrolls to the bottom of the
 * dashboard page.
 *
 * Without any lecture filtering (default), all lectures are shown. However,
 * to improve performance, we only load a limited number of lectures at once.
 * Only when the user scrolls again to the bottom of the page, more lectures are
 * loaded (infinite scrolling).
 *
 */
export default class extends Controller {
  static targets = ["form", "scrollObserver"];

  connect() {
    this.observer = new IntersectionObserver((entries) => {
      if (this.initiallyLoaded) return;
      entries.forEach((entry) => {
        if (!this.initiallyLoaded && entry.isIntersecting) {
          this.search();
          this.initiallyLoaded = true;
        }
      });
    }, { root: null, threshold: 0.1 });
    this.observer.observe(this.formTarget);
  }

  scrollObserverTargetConnected() {
    if (this.scrollObserver) {
      this.scrollObserver.disconnect();
    }
    if (!this.hasScrollObserverTarget) return;

    this.scrollObserver = new IntersectionObserver((entries) => {
      entries.forEach((entry) => {
        if (entry.isIntersecting) {
          this.retrieveNextPage();
        }
      });
    }, { root: null, rootMargin: "100px", threshold: 0.1 });
    this.scrollObserver.observe(this.scrollObserverTarget);
  }

  disconnect() {
    if (this.observer) {
      this.observer.disconnect();
    }
    if (this.scrollObserver) {
      this.scrollObserver.disconnect();
    }
  }

  /**
   * Triggers a search.
   *
   * We use a small delay to avoid too many requests.
   * This method is called whenever the user types in the search field.
   */
  search() {
    clearTimeout(this.timeout);
    this.timeout = setTimeout(() => {
      // Indicate to controller that we want the initial page for a new search.
      // This is especially important when the user has already scrolled down
      // and we were on a later page.
      addDataToForm(this.formTarget, { page: "" });
      this.formTarget.requestSubmit();
    }, 200);
  }

  /**
   * Retrieves the next page of results when the user scrolls to the bottom
   * of the page. This is important for performance when there are many results.
   *
   * This works together with the pagy keyset pagination.
   */
  retrieveNextPage() {
    const pagyDataElement = document.querySelector("#pagy-nav-next");
    if (!pagyDataElement) return;

    // Recursion-anchor: when no page token is present, we are at the end.
    // The Page string is base64-encoded by Pagy, but we shouldn't bother
    // about this implementation detail.
    const nextPage = pagyDataElement.dataset.nextPage;
    console.log(`Next page token: ${nextPage}`);
    if (!nextPage) return;

    addDataToForm(this.formTarget, { page: nextPage });
    this.formTarget.requestSubmit();
  }
}
