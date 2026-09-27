import { Controller } from "@hotwired/stimulus";

/**
 * Leaving a group replaces the participation list and the button with it, so
 * focus moves to the list's heading instead of falling back to the top of the
 * page. When the list is gone with the last group, focus goes to the row the
 * group can be joined from again.
 */
export default class extends Controller {
  static values = { fallback: String };

  connect() {
    this.keepFocus = this.keepFocus.bind(this);
    this.noteSubmit = () => {
      this.submitted = true;
    };
    document.addEventListener("turbo:before-stream-render", this.keepFocus);
    this.element.addEventListener("turbo:submit-start", this.noteSubmit);
  }

  disconnect() {
    document.removeEventListener("turbo:before-stream-render", this.keepFocus);
    this.element.removeEventListener("turbo:submit-start", this.noteSubmit);
  }

  keepFocus(event) {
    if (!this.submitted || event.target.target !== this.element.id) return;

    this.submitted = false;
    const render = event.detail.render;
    event.detail.render = async (stream) => {
      await render(stream);
      const heading = this.element.querySelector("h2");
      const fallback = document.getElementById(this.fallbackValue)?.querySelector("summary");
      (heading || fallback)?.focus();
    };
  }
}
