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
    this.inContainer = Boolean(this.element.closest("#modal-container"));
    this.markOpen = () => {
      this.isOpen = true;
    };
    this.markClosed = () => {
      this.isOpen = false;
    };
    this.element.addEventListener("show.bs.modal", this.markOpen);
    this.element.addEventListener("hidden.bs.modal", this.markClosed);
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
    this.element.removeEventListener("show.bs.modal", this.markOpen);
    this.element.removeEventListener("hidden.bs.modal", this.markClosed);
    if (this.element.dataset.modalClosingRemoved) return;

    if (this.isOpen && !this.inContainer) {
      this.closeRemoved();
      return;
    }

    if (this.modal) {
      try {
        if (this.isOpen) this.releasePage();
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

  /**
   * A modal in the page that a stream removes is closed the regular way,
   * which ends its focus trap and scroll lock; one still opening is closed
   * once shown. Not disposed, as that would also drop the window handlers of
   * the modal that replaced it.
   */
  closeRemoved() {
    const { element, modal } = this;
    element.dataset.modalClosingRemoved = "true";
    element.addEventListener("hidden.bs.modal", () => element.remove(), { once: true });
    element.addEventListener("shown.bs.modal", () => modal.hide(), { once: true });
    modal.hide();
  }

  /**
   * One in #modal-container is replaced by the next dialog, which opens at
   * once, so its page state goes right away rather than after a fade.
   */
  releasePage() {
    document.body.classList.remove("modal-open");
    document.body.style.removeProperty("overflow");
    document.body.style.removeProperty("padding-right");
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
      this.isOpen = false;
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
