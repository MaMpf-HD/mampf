import { Controller } from "@hotwired/stimulus";

/**
 * Reports a look at a sheet to the server: opening a row with something new on
 * it submits the row's hidden form, and the answer takes the marker away. A
 * link in the news line opens its row before the browser scrolls to it, so the
 * look counts there too.
 */
export default class extends Controller {
  static targets = ["report"];

  seen(event) {
    const details = event.currentTarget;
    if (!details.open) return;

    const report = this.reportTargets.find(form => details.contains(form));
    report?.requestSubmit();
  }

  open(event) {
    const id = event.currentTarget.getAttribute("href").slice(1);
    const details = document.getElementById(id);
    if (details) details.open = true;
  }
}
