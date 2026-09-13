import { Controller } from "@hotwired/stimulus";
import { Modal } from "bootstrap";

export default class extends Controller {
  static targets = ["form", "note", "saveButton"];

  connect() {
    this.modal = new Modal(this.element);
    window.addEventListener("exempt:open", this.open.bind(this));
    window.addEventListener("exempt:view", this.view.bind(this));
  }

  open(event) {
    this.formTarget.action = event.detail.url;
    this.originalNote = event.detail.note;
    this.noteTarget.value = event.detail.note || "";

    this.noteTarget.removeAttribute("readonly");
    this.saveButtonTarget.classList.remove("d-none");
    this.modal.show();
  }

  view(event) {
    this.noteTarget.value = event.detail.note;
    this.noteTarget.setAttribute("readonly", true);
    this.saveButtonTarget.classList.add("d-none");
    this.modal.show();
  }

  confirm() {
    this.modal.hide();
  }

  cancel() {
    this.modal.hide();
  }

  noteChanged() {
  }
}
