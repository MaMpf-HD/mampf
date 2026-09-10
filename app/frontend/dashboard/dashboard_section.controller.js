import { Controller } from "@hotwired/stimulus";

/**
 * A collapsible band of the dashboard's pinboard. The label is the button; the
 * caret in front of it turns from pointing down to pointing right when the
 * band is folded away.
 *
 * The choice is kept in localStorage, keyed by the band, so a folded band
 * stays folded across a reload and across the Turbo Stream swap that the
 * semester picker triggers (which re-renders both bands from scratch).
 */
export default class extends Controller {
  static targets = ["toggle", "cards"];
  static values = { key: String };

  connect() {
    if (this.storedState() === "collapsed") this.apply(false);
  }

  toggle() {
    const expanded = this.toggleTarget.getAttribute("aria-expanded") === "true";
    this.apply(!expanded);
    this.store(expanded ? "collapsed" : "expanded");
  }

  apply(expanded) {
    this.toggleTarget.setAttribute("aria-expanded", String(expanded));
    this.cardsTarget.hidden = !expanded;
  }

  storageKey() {
    return `dashboard-section:${this.keyValue}`;
  }

  storedState() {
    try {
      return window.localStorage.getItem(this.storageKey());
    }
    catch {
      return null;
    }
  }

  store(state) {
    try {
      window.localStorage.setItem(this.storageKey(), state);
    }
    catch {
      // a private window, or storage disabled: the fold just won't be remembered
    }
  }
}
