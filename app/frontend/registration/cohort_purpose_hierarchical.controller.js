import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = [
    "purposeCheckbox",
    "enrollmentWarning",
  ];

  togglePurpose() {
    if (!this.hasEnrollmentWarningTarget) return;

    const isChecked = this.purposeCheckboxTarget.checked;
    this.enrollmentWarningTarget.style.display = isChecked ? "flex" : "none";
  }
}
