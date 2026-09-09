import { Controller } from "@hotwired/stimulus";
import { Modal } from "bootstrap";

export default class extends Controller {
  static targets = ["checkbox", "reset", "dialog"];

  // Both directions turn every eligibility verdict in the lecture over, so
  // neither of them goes through unasked.
  change() {
    this.modal.show();
  }

  confirm() {
    this.submitOnceHidden(false);
  }

  reset() {
    this.submitOnceHidden(true);
  }

  // Back to where the box stood before the click, whichever way it went.
  cancel() {
    this.checkboxTarget.checked = !this.checkboxTarget.checked;
    this.modal.hide();
  }

  disconnect() {
    if (!this.hasDialogTarget) return;

    // Turbo can remove this element while the modal is open. Bootstrap then
    // never runs its own cleanup and `document.body` keeps the scroll lock.
    Modal.getInstance(this.dialogTarget)?.dispose();
    document.querySelector(".modal-backdrop")?.remove();
    document.body.classList.remove("modal-open");
    document.body.style.removeProperty("overflow");
    document.body.style.removeProperty("padding-right");
  }

  // Submitting during the fade disconnects the controller mid-animation, and
  // Bootstrap never restores `document.body`. So: submit on `hidden.bs.modal`.
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
