import { Controller } from "@hotwired/stimulus";
import { Modal } from "bootstrap";

export default class extends Controller {
  static values = { preventEventListener: Boolean };

  connect() {
    this.modal = Modal.getOrCreateInstance(this.element);
    if (!this.preventEventListenerValue) {
      this.element.addEventListener("turbo:submit-end", event => this.hideModalOnSuccess(event));
    }
  }

  disconnect() {
    if (this.modal) {
      this.modal.dispose();
    }
  }

  open() {
    this.modal.show();
  }

  hideModalOnSuccess(event) {
    if (!event.detail.success) return;

    if (this.modal) {
      this.element.querySelector("form")?.reset();
      this.modal.hide();
    }
  }
}
