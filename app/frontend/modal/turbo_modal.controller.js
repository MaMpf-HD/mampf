import { Controller } from "@hotwired/stimulus";
import { Modal } from "bootstrap";
import * as Turbo from "@hotwired/turbo";

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
