import { Controller } from "@hotwired/stimulus";

/**
 * Controller for banners that can be dismissed permanently (per browser).
 *
 * The banner element should be rendered with the `hidden` attribute so that
 * users who have already dismissed it do not see a flash of content. On
 * connect, the banner is revealed unless a dismissal has been recorded in
 * localStorage under the configured key.
 *
 * When localStorage is unavailable (e.g. blocked by browser settings), the
 * banner is shown and dismissals last only for the current page view.
 *
 * Usage:
 *   <div hidden
 *        data-controller="dismissible-banner"
 *        data-dismissible-banner-key-value="someBanner:dismissed">
 *     ...
 *     <button data-action="dismissible-banner#dismiss">...</button>
 *   </div>
 */
export default class extends Controller {
  static values = { key: String };

  connect() {
    if (this.isDismissed()) {
      this.element.remove();
    }
    else {
      this.element.hidden = false;
    }
  }

  dismiss() {
    if (this.hasKeyValue) {
      try {
        localStorage.setItem(this.keyValue, "true");
      }
      catch {
        // storage unavailable: the dismissal lasts only for this page view
      }
    }
    this.element.remove();
  }

  isDismissed() {
    if (!this.hasKeyValue) return false;

    try {
      return Boolean(localStorage.getItem(this.keyValue));
    }
    catch {
      // storage unavailable: we cannot remember dismissals, so show the
      // banner rather than hiding it forever
      return false;
    }
  }
}
