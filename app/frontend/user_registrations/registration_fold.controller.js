import { Controller } from "@hotwired/stimulus";

/**
 * Opens a campaign when a link on the page points at it, and says in its
 * collapsed row when its choices are not saved yet.
 */
export default class extends Controller {
  static targets = ["unsaved"];

  connect() {
    this.openFromHash = this.openFromHash.bind(this);
    window.addEventListener("hashchange", this.openFromHash);
    this.openFromHash();
  }

  disconnect() {
    window.removeEventListener("hashchange", this.openFromHash);
  }

  openFromHash() {
    if (window.location.hash !== `#${this.element.id}`) return;

    this.element.open = true;
    this.element.querySelector("summary")?.focus();
  }

  markUnsaved(event) {
    if (this.hasUnsavedTarget) this.unsavedTarget.hidden = !event.detail.changed;
  }
}
