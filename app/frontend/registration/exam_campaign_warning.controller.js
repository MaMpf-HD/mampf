import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["alert"];
  static values = { isExam: Boolean };

  connect() {
    this.toggleWarning();
    this.element.addEventListener("change", () => this.toggleWarning());
  }

  toggleWarning() {
    if (!this.hasAlertTarget) return;
    if (!this.isExamValue) return;

    const selectedValue = this.element.value;
    const isPreferenceBased = selectedValue === "preference_based";

    if (isPreferenceBased) {
      this.alertTarget.classList.remove("d-none");
    }
    else {
      this.alertTarget.classList.add("d-none");
    }
  }
}
