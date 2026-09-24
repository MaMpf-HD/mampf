import { Controller } from "@hotwired/stimulus";
import { Turbo } from "@hotwired/turbo-rails";

/**
 * Opens a campaign when a link on the page points at it, loads its options
 * the first time it opens, and says in its collapsed row when its choices are
 * not saved yet. When a registration step replaces the options, the button
 * that was pressed is gone, so focus moves to the campaign's row instead of
 * falling back to the top of the page.
 */
export default class extends Controller {
  static targets = ["unsaved", "body"];
  static values = { url: String };

  connect() {
    this.openFromHash = this.openFromHash.bind(this);
    this.keepFocus = this.keepFocus.bind(this);
    this.noteSubmit = () => {
      this.submitted = true;
    };
    window.addEventListener("hashchange", this.openFromHash);
    document.addEventListener("turbo:before-stream-render", this.keepFocus);
    this.element.addEventListener("turbo:submit-start", this.noteSubmit);
    this.openFromHash();
  }

  disconnect() {
    window.removeEventListener("hashchange", this.openFromHash);
    document.removeEventListener("turbo:before-stream-render", this.keepFocus);
    this.element.removeEventListener("turbo:submit-start", this.noteSubmit);
  }

  keepFocus(event) {
    if (!this.submitted || !this.hasBodyTarget) return;
    if (event.target.target !== this.bodyTarget.id) return;

    this.submitted = false;
    const render = event.detail.render;
    event.detail.render = async (stream) => {
      await render(stream);
      this.element.querySelector("summary")?.focus();
    };
  }

  openFromHash() {
    if (window.location.hash !== `#${this.element.id}`) return;

    this.element.open = true;
    this.element.querySelector("summary")?.focus();
  }

  async load() {
    if (!this.element.open || !this.hasUrlValue || !this.hasBodyTarget) return;
    if (this.bodyTarget.dataset.loaded === "true" || this.loading) return;

    this.loading = true;
    try {
      const response = await fetch(this.urlValue, {
        headers: {
          "accept": "text/vnd.turbo-stream.html",
          "X-Requested-With": "XMLHttpRequest",
        },
        credentials: "same-origin",
      });
      if (response.ok) Turbo.renderStreamMessage(await response.text());
    }
    finally {
      this.loading = false;
    }
  }

  markUnsaved(event) {
    if (this.hasUnsavedTarget) this.unsavedTarget.hidden = !event.detail.changed;
  }
}
