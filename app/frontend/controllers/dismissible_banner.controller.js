import { Controller } from "@hotwired/stimulus";

/**
 * Controller for banners that can be dismissed permanently (per browser).
 *
 * The banner element should be rendered with the `hidden` attribute so that
 * users who have already dismissed it do not see a flash of content. On
 * connect, the banner is revealed unless a dismissal has been recorded in
 * localStorage under the configured key.
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
    if (this.hasKeyValue && localStorage.getItem(this.keyValue)) {
      this.element.remove();
    }
    else {
      this.element.hidden = false;
    }
  }

  dismiss() {
    if (this.hasKeyValue) {
      localStorage.setItem(this.keyValue, "true");
    }
    this.element.remove();
  }
}
