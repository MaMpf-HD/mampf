import { Controller } from "@hotwired/stimulus";
import { Modal } from "bootstrap";

export default class extends Controller {
  connect() {
    this.modal = Modal.getOrCreateInstance(this.element);
    this.element.addEventListener("turbo:submit-end", () => this.hideModalOnSuccess(event));
  }

  disconnect() {
    if (this.modal) {
      this.modal.dispose();
    }
  }

  hideModalOnSuccess(event) {
    if (!event.detail.success) return;

    if (this.modal) {
      this.element.querySelector("form")?.reset();
      this.modal.hide();
    }
  }
}
