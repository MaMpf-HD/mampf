import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["registrationDeadline", "submitButton", "cancelButton", "warning"];

  connect() {
    if (!this.hasRegistrationDeadlineTarget) return;

    this.storeOriginalValues();

    if (this.registrationDeadlineTarget.classList.contains("is-invalid")) {
      this.showSubmitElements();
    }
    else {
      this.hideSubmitElements();
    }
  }

  storeOriginalValues() {
    this.originalDeadline = this.registrationDeadlineTarget.value;
  }

  checkForChanges() {
    if (!this.hasRegistrationDeadlineTarget) return;

    const deadlineChanged = this.registrationDeadlineTarget.value !== this.originalDeadline;

    if (deadlineChanged) {
      this.showSubmitElements();
    }
    else {
      this.hideSubmitElements();
    }
  }

  showSubmitElements() {
    if (this.hasSubmitButtonTarget) {
      this.submitButtonTarget.classList.remove("d-none");
    }
    if (this.hasCancelButtonTarget) {
      this.cancelButtonTarget.classList.remove("d-none");
    }
    if (this.hasWarningTarget) {
      this.warningTarget.classList.remove("d-none");
    }
  }

  hideSubmitElements() {
    if (this.hasSubmitButtonTarget) {
      this.submitButtonTarget.classList.add("d-none");
    }
    if (this.hasCancelButtonTarget) {
      this.cancelButtonTarget.classList.add("d-none");
    }
    if (this.hasWarningTarget) {
      this.warningTarget.classList.add("d-none");
    }
  }

  cancel() {
    if (!this.hasRegistrationDeadlineTarget) return;

    this.registrationDeadlineTarget.value = this.originalDeadline;
    this.hideSubmitElements();
  }

  resetAfterSave() {
    if (!this.hasRegistrationDeadlineTarget) return;

    this.storeOriginalValues();
    this.hideSubmitElements();
  }
}
