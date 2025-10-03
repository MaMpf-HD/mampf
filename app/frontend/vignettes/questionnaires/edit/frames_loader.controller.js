import { Controller } from "@hotwired/stimulus";

/**
 * Shows a spinner while multiple Turbo Frames are loading.
 * Once all frames have loaded, the spinner is removed and the content is shown.
 *
 * Expected to be used on a div that contains multiple turbo-frame elements.
 */
export default class extends Controller {
  connect() {
    this.createSpinner();
    this.wrapContent();

    this.frames = Array.from(this.contentWrapper.querySelectorAll("turbo-frame"));
    this.total = this.frames.length;
    this.loaded = new Set();

    if (this.total === 0) {
      this.finish();
      return;
    }

    this.frames.forEach((frame) => {
      if (frame.innerHTML && frame.innerHTML.trim().length > 0) {
        this.loaded.add(frame);
      }
    });

    if (this.loaded.size >= this.total) {
      this.finish();
      return;
    }

    this.boundOnFrameRender = this.onFrameRender.bind(this);
    this.contentWrapper.addEventListener("turbo:frame-render", this.boundOnFrameRender);
  }

  createSpinner() {
    this.spinner = document.createElement("div");
    this.spinner.className = "text-center my-2";
    this.spinner.setAttribute("aria-hidden", "true");

    const inner = document.createElement("div");
    inner.className = "spinner-border";
    inner.setAttribute("role", "status");
    inner.setAttribute("aria-hidden", "true");
    this.spinner.appendChild(inner);

    this.element.insertBefore(this.spinner, this.element.firstChild);
  }

  wrapContent() {
    this.contentWrapper = document.createElement("div");
    this.contentWrapper.className = "d-none";
    this.contentWrapper.setAttribute("aria-hidden", "true");

    const children = Array.from(this.element.childNodes);
    children.forEach((node) => {
      if (node === this.spinner) return;
      this.contentWrapper.appendChild(node);
    });

    this.element.appendChild(this.contentWrapper);
  }

  disconnect() {
    if (this.boundOnFrameRender && this.contentWrapper) {
      this.contentWrapper.removeEventListener("turbo:frame-render", this.boundOnFrameRender);
    }
  }

  onFrameRender(event) {
    const frame = event.target;
    if (!frame || frame.tagName.toLowerCase() !== "turbo-frame") return;
    if (!this.contentWrapper.contains(frame)) return;

    this.loaded.add(frame);
    if (this.loaded.size >= this.total) {
      this.finish();
      if (this.boundOnFrameRender) {
        this.contentWrapper.removeEventListener("turbo:frame-render", this.boundOnFrameRender);
      }
    }
  }

  finish() {
    if (this.spinner && this.spinner.parentNode) this.spinner.remove();
    if (this.contentWrapper) {
      this.contentWrapper.classList.remove("d-none");
      this.contentWrapper.removeAttribute("aria-hidden");
    }
  }
}
