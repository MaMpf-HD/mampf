import { Controller } from "@hotwired/stimulus";
import { Modal } from "bootstrap";
import * as Turbo from "@hotwired/turbo";

/**
 * Don't use this controller!
 *
 * Controller for opening modals with Turbo content.
 */
export default class extends Controller {
  static values = {
    selector: String,
    frameId: String,
  };

  async open(event) {
    event.preventDefault();

    const modalEl = document.querySelector(this.selectorValue);
    if (!modalEl) return;

    const modal = Modal.getOrCreateInstance(modalEl);
    modal.show();

    const url = this.element.getAttribute("href");

    try {
      // TODO: We should find a better way to load modals without having
      // to make our own fetch request and render the response manually.
      // I've tried out Rails Request.JS (https://github.com/rails/request.js)
      // and it works fine. However, even with that, it feels like there are
      // simpler solutions out there. When you search for blog posts about
      // Modals with Turbo, you will find lots of different approaches that
      // are easier than this and generalize better.
      // We use this here for now, but should check for better solutions
      // in case we need more modal forms.
      const response = await fetch(url, {
        headers: {
          "Accept": "text/vnd.turbo-stream.html, text/html, application/xhtml+xml",
          "Turbo-Frame": this.frameIdValue,
        },
      });

      if (response.ok) {
        const html = await response.text();
        Turbo.renderStreamMessage(html);
      }
      else {
        console.error("Failed to load modal content:", response.statusText);
        this.showModalLoadingErrorMessage(modalEl);
      }
    }
    catch (error) {
      console.error("Network error loading modal content:", error);
      this.showModalLoadingErrorMessage(modalEl);
    }
  }

  showModalLoadingErrorMessage(modalEl) {
    const body = modalEl.querySelector(".modal-body");
    if (!body) {
      console.error("Modal body element not found.");
      return;
    }

    const alert = document.createElement("div");
    alert.className = "alert alert-danger";
    alert.setAttribute("role", "alert");

    const meta = document.querySelector('meta[name="turbo-modal-error-message"]');
    const message = meta?.content || "An error occurred.";

    alert.textContent = message;
    body.replaceChildren(alert);
  }
}
