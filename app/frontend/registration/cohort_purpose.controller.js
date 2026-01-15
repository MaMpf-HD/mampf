import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = [
    "typeSelect",
    "purposeField",
    "propagateContainer",
    "propagateCheckbox",
  ];

  connect() {
    this.togglePurpose();
  }

  togglePurpose() {
    const type = this.typeSelectTarget.value;
    const isCohortType = ["Enrollment Group", "Planning Survey", "Other Group"].includes(type);

    if (isCohortType) {
      this.updatePurposeAndPropagate(type);
    }
    else {
      this.propagateContainerTarget.style.display = "none";
    }
  }

  updatePurposeAndPropagate(type) {
    const mapping = {
      "Enrollment Group": { purpose: "enrollment", propagate: true, showCheckbox: false },
      "Planning Survey": { purpose: "planning", propagate: false, showCheckbox: false },
      "Other Group": { purpose: "general", propagate: true, showCheckbox: true },
    };

    const config = mapping[type];
    if (!config) return;

    this.purposeFieldTarget.value = config.purpose;

    if (config.showCheckbox) {
      this.propagateContainerTarget.style.display = "block";
      this.propagateCheckboxTarget.checked = config.propagate;
    }
    else {
      this.propagateContainerTarget.style.display = "none";
      this.propagateCheckboxTarget.checked = config.propagate;
    }
  }
}
