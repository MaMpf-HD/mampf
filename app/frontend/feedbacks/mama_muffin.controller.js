import { Controller } from "@hotwired/stimulus";

const ONE_YEAR = 60 * 60 * 24 * 365;

/**
 * Clicks Mama Muffin away for good: the cookie keeps the dashboard from
 * rendering her again (see `FeedbacksHelper#show_mama_muffin?`).
 */
export default class extends Controller {
  static values = { cookie: String };

  dismiss() {
    document.cookie = `${this.cookieValue}=1; max-age=${ONE_YEAR}; path=/; samesite=lax`;
    this.element.remove();
  }
}
