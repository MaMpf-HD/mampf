import { Controller } from "@hotwired/stimulus";
import { Modal } from "bootstrap";

export default class extends Controller {
  static values = {
    showOnConnect: Boolean,
    // A modal holding more than one form would close on the wrong one, so it
    // opts out here and binds hideModalOnSuccess to the form that owns it.
    keepOpenOnSubmit: Boolean,
  };

  connect() {
    this.modal = Modal.getOrCreateInstance(this.element);
    this.boundHideModalOnSuccess = this.hideModalOnSuccess.bind(this);
    if (!this.keepOpenOnSubmitValue) {
      this.element.addEventListener(
        "turbo:submit-end", this.boundHideModalOnSuccess,
      );
    }

    if (this.showOnConnectValue) {
      this.modal.show();
    }
  }

  open() {
    this.modal.show();
  }

  disconnect() {
    this.element.removeEventListener(
      "turbo:submit-end", this.boundHideModalOnSuccess,
    );

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

      const container = document.getElementById("modal-container");

      if (!container?.contains(this.element)) {
        // A modal that lives in the page outlives the submission, so it has to
        // be hidden. Disposing it would leave it on screen with nothing left
        // to close it.
        this.modal.hide();
        return;
      }

      // Dispose modal immediately to prevent Bootstrap trying to access
      // removed DOM elements during hide animation
      this.modal.dispose();

      // Clear modal container
      container.innerHTML = "";

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
