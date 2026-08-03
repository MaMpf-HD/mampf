import { Controller } from "@hotwired/stimulus";

// Reveals the save button only once a field actually differs from what was
// loaded, and puts every field back on cancel. Which fields those are is the
// form's business, not this controller's — it watches whatever is marked.
export default class extends Controller {
  static targets = ["submitButton", "warning", "field"];

  connect() {
    this.storeOriginalValues();
    this.hideSubmitElements();
  }

  storeOriginalValues() {
    this.originalValues = this.fieldTargets.map(field => currentValue(field));
  }

  checkForChanges() {
    const changed = this.fieldTargets
      .some((field, index) => currentValue(field) !== this.originalValues[index]);

    if (changed) {
      this.showSubmitElements();
    }
    else {
      this.hideSubmitElements();
    }
  }

  cancel() {
    this.fieldTargets.forEach((field, index) => {
      if (field.type === "checkbox") {
        field.checked = this.originalValues[index];
      }
      else {
        field.value = this.originalValues[index];
      }
    });
    this.hideSubmitElements();
  }

  resetAfterSave(event) {
    if (!event.detail.success) {
      return;
    }

    this.storeOriginalValues();
    this.hideSubmitElements();
  }

  showSubmitElements() {
    this.submitButtonTarget.classList.remove("d-none");
    this.warningTarget.classList.remove("d-none");
  }

  hideSubmitElements() {
    this.submitButtonTarget.classList.add("d-none");
    this.warningTarget.classList.add("d-none");
  }
}

function currentValue(field) {
  return field.type === "checkbox" ? field.checked : field.value;
}
