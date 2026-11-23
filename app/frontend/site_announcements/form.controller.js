import { Controller } from "@hotwired/stimulus";

/**
 * Previews the draft for the announcement in the banner above the navbar.
 */
export default class extends Controller {
  static values = { separator: String };

  disconnect() {
    this.#restore();
  }

  /** Closes the form by emptying the frame it was loaded into. */
  cancel() {
    this.#restore();
    const frame = this.element.closest("turbo-frame");
    frame.removeAttribute("src");
    frame.replaceChildren();
  }

  update(event) {
    const banner = this.#banner();
    if (!banner) return;

    const draft = event.target.value;
    if (!draft) {
      this.#restore();
      return;
    }
    banner.innerHTML = this.original.hidden
      ? draft
      : draft + this.separatorValue + this.original.html;
    banner.hidden = false;
  }

  #banner() {
    const banner = document.querySelector("#site-announcement-banner .alert");
    if (banner && banner !== this.banner) {
      this.banner = banner;
      this.original = { html: banner.innerHTML, hidden: banner.hidden };
    }
    return banner;
  }

  #restore() {
    if (!this.banner) return;
    this.banner.innerHTML = this.original.html;
    this.banner.hidden = this.original.hidden;
  }
}
