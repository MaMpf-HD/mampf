import { Controller } from "@hotwired/stimulus";
import { Modal } from "bootstrap";

// Ticking the box submits at once. Unticking it while computed decisions
// exist asks first, because the rule takes every one of them back the moment
// the list reopens.
export default class extends Controller {
  static targets = ["checkbox", "reset", "dialog"];

  change() {
    if (this.checkboxTarget.checked || !this.hasDialogTarget) {
      this.submit(false);
      return;
    }

    this.modal.show();
  }

  keep() {
    this.submitOnceHidden(false);
  }

  reset() {
    this.submitOnceHidden(true);
  }

  cancel() {
    this.checkboxTarget.checked = true;
    this.modal.hide();
  }

  disconnect() {
    if (!this.hasDialogTarget) return;

    // Whatever state the modal is in when the page goes, the body must not
    // keep the scroll lock it put there.
    Modal.getInstance(this.dialogTarget)?.dispose();
    document.querySelector(".modal-backdrop")?.remove();
    document.body.classList.remove("modal-open");
    document.body.style.removeProperty("overflow");
    document.body.style.removeProperty("padding-right");
  }

  // The modal fades out on its own time and only then hands the body back.
  // Navigating away in the middle of that leaves the fade's callback with a
  // disposed modal and the body without its scrollbar, so the form waits.
  submitOnceHidden(resetCertifications) {
    this.dialogTarget.addEventListener(
      "hidden.bs.modal",
      () => this.submit(resetCertifications),
      { once: true },
    );
    this.modal.hide();
  }

  submit(resetCertifications) {
    this.resetTarget.value = resetCertifications ? "1" : "0";
    this.element.requestSubmit();
  }

  get modal() {
    return Modal.getOrCreateInstance(this.dialogTarget);
  }
}
