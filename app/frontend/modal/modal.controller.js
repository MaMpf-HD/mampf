import { Controller } from "@hotwired/stimulus";
import { Modal } from "bootstrap";

export default class extends Controller {
  connect() {
    this.modal = Modal.getOrCreateInstance(this.element);
    this.element.addEventListener("turbo:submit-end", event => this.hideModalOnSuccess(event));
    this.element.addEventListener("shown.bs.modal", () => this.initializeSelects());
  }

  disconnect() {
    if (this.modal) {
      this.modal.dispose();
    }
  }

  show() {
    if (this.modal) {
      this.modal.show();
    }
  }

  initializeSelects() {
    if (typeof window.fillOptionsByAjax === "function") {
      window.fillOptionsByAjax($(this.element).find(".selectize"));
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
