import { Controller } from "@hotwired/stimulus";
import { Modal } from "bootstrap";

export default class extends Controller {
  static targets = ["form", "note"];

  connect() {
    this.modal = new Modal(this.element);
    window.addEventListener("exempt:open", this.open.bind(this));
  }

  open(event) {
    this.formTarget.action = event.detail.url;
    this.noteTarget.value = "";
    this.modal.show();
  }
}
