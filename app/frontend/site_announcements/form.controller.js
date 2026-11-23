import { Controller } from "@hotwired/stimulus";

/**
 * Inline form for a new site announcement. Previews the text being written in
 * the banner above the navbar, on top of the announcements already shown
 * there, i.e. as it will look once published. The banner is restored when the
 * form goes away (cancel or publish).
 */
export default class extends Controller {
  static values = { separator: String };

  disconnect() {
    this.#restore();
  }

  /** Closes the form by emptying the frame it was loaded into. */
  cancel() {
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

  /**
   * The banner's alert. When the server swapped the banner meanwhile (e.g. an
   * announcement was switched on), its new content is the one to restore.
   */
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
