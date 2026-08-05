import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = [
    "display", "edit",
    "statusSelect", "noteInput",
    "form", "statusHidden", "noteHidden",
  ];

  toggleEdit() {
    this.displayTargets.forEach(el => el.classList.add("d-none"));
    this.editTargets.forEach(el => el.classList.remove("d-none"));
    this.statusSelectTarget.focus();
  }

  cancel() {
    this.displayTargets.forEach(el => el.classList.remove("d-none"));
    this.editTargets.forEach(el => el.classList.add("d-none"));
  }

  save() {
    this.statusHiddenTarget.value = this.statusSelectTarget.value;
    this.noteHiddenTarget.value = this.noteInputTarget.value;
    this.formTarget.requestSubmit();
  }
}
