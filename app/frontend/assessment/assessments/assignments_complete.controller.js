import { Controller } from "@hotwired/stimulus";
import { Modal } from "bootstrap";

export default class extends Controller {
  static targets = ["checkbox", "reset", "dialog"];

  connect() {
    // A dialog goes away by more than its own button: Escape, a click beside
    // it, or Bootstrap being disposed. Every one of them leaves a question
    // unanswered, and the box has to go back to where it stood - so the
    // restoring hangs on the dialog closing rather than on the button.
    this.restore = () => this.restoreUnlessAnswered();
    this.dialogTarget.addEventListener("hidden.bs.modal", this.restore);
  }

  // Both directions turn every eligibility verdict in the lecture over, so
  // neither of them goes through unasked.
  change() {
    this.answered = false;
    this.stood = !this.checkboxTarget.checked;
    this.modal.show();
  }

  confirm() {
    this.submitOnceHidden(false);
  }

  reset() {
    this.submitOnceHidden(true);
  }

  cancel() {
    this.modal.hide();
  }

  // Put back, not flipped: dismissing twice must not toggle the box twice.
  restoreUnlessAnswered() {
    if (this.answered) return;

    this.checkboxTarget.checked = this.stood;
  }

  disconnect() {
    if (!this.hasDialogTarget) return;

    this.dialogTarget.removeEventListener("hidden.bs.modal", this.restore);

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
    this.answered = true;
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
