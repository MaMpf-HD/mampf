import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["mainInput", "submit"];

  connect() {
    this.registerEnterSubmitHandler();
    this.registerFormValidator();
  }

  registerEnterSubmitHandler() {
    this.element.addEventListener("keydown", (event) => {
      if (event.ctrlKey && event.key === "Enter") {
        this.submit();
      }
    });
  }

  registerFormValidator() {
    this.element.addEventListener("input", () => {
      this.validateMainInput(this.mainInputTarget);
    });
  }

  validateMainInput(input) {
    const validityState = input.validity;

    if (validityState.tooShort) {
      input.setCustomValidity(input.dataset.tooShortMessage);
    }
    else if (validityState.valueMissing) {
      input.setCustomValidity(input.dataset.valueMissingMessage);
    }
    else {
      input.setCustomValidity("");
    }

    input.reportValidity();
  }

  submit() {
    this.validateMainInput(this.mainInputTarget);
    this.submitTarget.click();
  }
}
