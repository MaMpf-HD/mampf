import { Controller } from "@hotwired/stimulus";
import { Modal } from "bootstrap";

export default class extends Controller {
  connect() {
    this.modal = new Modal(this.element);
    this.modal.show();
    this.element.addEventListener("turbo:submit-end", () => this.hideModalOnSuccess(event));
  }

  disconnect() {
    this.modal.dispose();
  }

  hideModalOnSuccess(event) {
    if (!event.detail.success) return;

    if (this.modal) {
      this.modal.hide();
    }
  }
}
