import { Controller } from "@hotwired/stimulus";

/**
 * Controller that loads all lectures when the user scrolls to the bottom of the
 * page.
 */
export default class extends Controller {
  static targets = ["form", "scrollObserver"];

  connect() {
    this.isFetchingNextPage = false;

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
    },
    {
      root: null,
      rootMargin: "100px",
      threshold: 0.1,
    });

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
   * Triggers a search when the user types in the search field.
   *
   * We use a small delay to avoid too many requests.
   */
  search() {
    clearTimeout(this.timeout);
    this.timeout = setTimeout(() => {
      this.formTarget.requestSubmit();
    }, 200);
  }

  /**
   * Retrieves the next page of results when the user scrolls to the bottom
   * of the page. This is important for performance when there are many results.
   *
   * This works together with the pagy keyset or rather keynav_js pagination.
   */
  retrieveNextPage() {
    if (this.isFetchingNextPage) return;

    const navContainer = document.querySelector("#pagy-nav-container");
    if (!navContainer) return;

    const nextPageUrl = navContainer.dataset.nextPageUrl;
    if (!nextPageUrl) return;

    console.log("Fetching next page:", nextPageUrl);
    const url = new URL(nextPageUrl, window.location.origin);
    const pageValue = url.searchParams.get("page");

    // Add or update hidden page input
    let pageInput = this.formTarget.querySelector("input[name='page']");
    if (!pageInput) {
      pageInput = document.createElement("input");
      pageInput.type = "hidden";
      pageInput.name = "page";
      this.formTarget.appendChild(pageInput);
    }
    pageInput.value = pageValue;

    this.isFetchingNextPage = true;
    this.formTarget.addEventListener("turbo:submit-end", () => {
      this.isFetchingNextPage = false;
    }, { once: true });

    console.log(`Targetting page ${pageValue}`);
    console.log(`Final form URL: ${this.formTarget.action}?${new URLSearchParams(new FormData(this.formTarget)).toString()}`);

    this.formTarget.requestSubmit();
  }
}
