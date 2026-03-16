import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["threshold", "title", "valueType", "thresholdInput",
    "description", "submitButton", "warning"];

  connect() {
    this.toggle();
    if (this.hasTitleTarget) {
      this.storeOriginalValues();
      this.hideSubmitElements();
    }
  }

  storeOriginalValues() {
    this.originalTitle = this.titleTarget.value;
    this.originalValueType = this.valueTypeTarget.value;
    this.originalThreshold = this.thresholdInputTarget.value;
    this.originalDescription = this.descriptionTarget.value;
  }

  toggle() {
    if (!this.hasValueTypeTarget) return;

    const isBoolean = this.valueTypeTarget.value === "boolean";
    this.thresholdTarget.style.display = isBoolean ? "none" : "";

    if (isBoolean) {
      this.thresholdInputTarget.value = "";
    }
  }

  checkForChanges() {
    const changed = this.titleTarget.value !== this.originalTitle
      || this.valueTypeTarget.value !== this.originalValueType
      || this.thresholdInputTarget.value !== this.originalThreshold
      || this.descriptionTarget.value !== this.originalDescription;

    if (changed) {
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
    this.valueTypeTarget.value = this.originalValueType;
    this.thresholdInputTarget.value = this.originalThreshold;
    this.descriptionTarget.value = this.originalDescription;
    this.toggle();
    this.hideSubmitElements();
  }

  resetAfterSave() {
    this.storeOriginalValues();
    this.hideSubmitElements();
  }
}
