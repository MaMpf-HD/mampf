import { Controller } from "@hotwired/stimulus";
import { Modal } from "bootstrap";

export default class extends Controller {
  static targets = ["form", "note"];

  connect() {
    this.modal = new Modal(this.element);
  }

  disconnect() {
    this.modal.dispose();
  }

  open({ detail: { url, note } }) {
    this.formTarget.action = url;
    this.noteTarget.value = note || "";
    this.modal.show();
  }

  hide() {
    this.modal.hide();
  }
}
