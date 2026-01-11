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
      catch (e) {
        // Modal already disposed or element removed
      }
    }
  }

  hideModalOnSuccess(event) {
    if (!event.detail.success) return;

    if (this.modal) {
      this.element.querySelector("form")?.reset();

      this.element.addEventListener("hidden.bs.modal", () => {
        const container = document.getElementById("modal-container");
        if (container) {
          container.innerHTML = "";
        }
      }, { once: true });

      this.modal.hide();
    }
  }
}
