import { Controller } from "@hotwired/stimulus";

/**
 * Previews the draft for the announcement in the banner above the navbar.
 */
export default class extends Controller {
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
    const banner = document.querySelector("#site-announcement-banner .alert");
    if (!banner) return;

    const draft = event.target.value;
    if (!draft) {
      this.#restore();
      return;
    }

    // A Turbo Stream may have replaced the banner, and the preview with it.
    if (!this.preview?.isConnected) {
      this.preview = document.createElement("div");
      this.preview.className = "site-announcement";
      banner.prepend(this.preview);
    }
    this.preview.innerHTML = draft;
    banner.hidden = false;
  }

  #restore() {
    if (!this.preview) return;

    const banner = this.preview.parentElement;
    this.preview.remove();
    this.preview = null;
    if (banner) banner.hidden = !banner.querySelector(".site-announcement");
  }
}
