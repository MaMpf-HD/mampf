import { Controller } from "@hotwired/stimulus";
import { Turbo } from "@hotwired/turbo-rails";

/**
 * When a registration step replaces a campaign's options, the button that was
 * pressed is gone; focus moves to the campaign's row instead of the top of
 * the page.
 */
export default class extends Controller {
  static targets = ["unsaved", "body"];
  static values = { url: String, failedLabel: String, retryLabel: String };

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
      else this.showFailure();
    }
    catch {
      this.showFailure();
    }
    finally {
      this.loading = false;
    }
  }

  // Says so when the options did not arrive, for instance because the
  // campaign closed since the page was loaded, and offers to try again.
  showFailure() {
    const message = document.createElement("p");
    message.className = "registration-fold-loading mb-0";
    message.textContent = `${this.failedLabelValue} `;
    const retry = document.createElement("button");
    retry.type = "button";
    retry.className = "btn btn-link btn-sm p-0 align-baseline";
    retry.textContent = this.retryLabelValue;
    retry.addEventListener("click", () => this.load());
    message.append(retry);
    this.bodyTarget.replaceChildren(message);
  }

  markUnsaved(event) {
    if (this.hasUnsavedTarget) this.unsavedTarget.hidden = !event.detail.changed;
  }
}
