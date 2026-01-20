import { Controller } from "@hotwired/stimulus";
import { Modal } from "bootstrap";

export default class extends Controller {
  static values = {
    showOnConnect: Boolean,
  };

  connect() {
    this.modal = Modal.getOrCreateInstance(this.element);
    this.element.addEventListener("turbo:submit-end", event => this.hideModalOnSuccess(event));

    if (this.showOnConnectValue) {
      this.modal.show();
    }
  }

  disconnect() {
    if (this.modal) {
      try {
        const backdrop = document.querySelector(".modal-backdrop");
        if (backdrop) {
          backdrop.remove();
        }
        this.modal.dispose();
      }
      catch {
        // Modal already disposed or element removed
      }
    }
  }

  hideModalOnSuccess(event) {
    if (!event.detail.success) return;

    if (this.modal && this.element.isConnected) {
      this.element.querySelector("form")?.reset();

      // Dispose modal immediately to prevent Bootstrap trying to access
      // removed DOM elements during hide animation
      this.modal.dispose();

      // Clear modal container
      const container = document.getElementById("modal-container");
      if (container) {
        container.innerHTML = "";
      }

      // Remove backdrop manually if it exists
      const backdrop = document.querySelector(".modal-backdrop");
      if (backdrop) {
        backdrop.remove();
      }

      // Restore body scroll
      document.body.classList.remove("modal-open");
      document.body.style.removeProperty("overflow");
      document.body.style.removeProperty("padding-right");
    }
  }
}
