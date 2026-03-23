import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["submitButton", "warning", "title", "deadline", "mediumId",
    "acceptedFileType", "requiresSubmission"];

  connect() {
    this.storeOriginalValues();
    this.hideSubmitElements();
  }

  storeOriginalValues() {
    this.originalTitle = this.titleTarget.value;
    this.originalDeadline = this.deadlineTarget.value;
    this.originalMediumId = this.mediumIdTarget.value;
    this.originalAcceptedFileType = this.acceptedFileTypeTarget.value;
    if (this.hasRequiresSubmissionTarget) {
      this.originalRequiresSubmission = this.requiresSubmissionTarget.checked;
    }
  }

  checkForChanges() {
    const titleChanged = this.titleTarget.value !== this.originalTitle;
    const deadlineChanged = this.deadlineTarget.value !== this.originalDeadline;
    const mediumIdChanged = this.mediumIdTarget.value !== this.originalMediumId;
    const fileTypeChanged = this.acceptedFileTypeTarget.value !== this.originalAcceptedFileType;
    const requiresSubmissionChanged = this.hasRequiresSubmissionTarget
      && this.requiresSubmissionTarget.checked !== this.originalRequiresSubmission;

    if (titleChanged || deadlineChanged || mediumIdChanged
      || fileTypeChanged || requiresSubmissionChanged) {
      this.showSubmitElements();
    }
    else {
      this.hideSubmitElements();
    }
  }

  showSubmitElements() {
    this.submitButtonTarget.classList.remove("d-none");
    this.warningTarget.classList.remove("d-none");
  }

  hideSubmitElements() {
    this.submitButtonTarget.classList.add("d-none");
    this.warningTarget.classList.add("d-none");
  }

  cancel() {
    this.titleTarget.value = this.originalTitle;
    this.deadlineTarget.value = this.originalDeadline;
    this.mediumIdTarget.value = this.originalMediumId;
    this.acceptedFileTypeTarget.value = this.originalAcceptedFileType;
    if (this.hasRequiresSubmissionTarget) {
      this.requiresSubmissionTarget.checked = this.originalRequiresSubmission;
    }
    this.hideSubmitElements();
  }

  resetAfterSave() {
    this.storeOriginalValues();
    this.hideSubmitElements();
  }
}
