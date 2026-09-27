import { Controller } from "@hotwired/stimulus";

const FEEDBACK_DURATION = 1500;
const SUCCESS_ICON = "bi-check2";
const FAILURE_ICON = "bi-exclamation-triangle";

export default class extends Controller {
  static targets = ["icon", "status"];
  static values = {
    text: String,
    confirmation: String,
    failure: String,
    // What the button shows when it is not saying anything: an envelope where
    // an address is copied, a clipboard where a code is.
    restingIcon: { type: String, default: "bi-envelope" },
  };

  copy(event) {
    event.preventDefault();

    // Only a secure context has a clipboard, so plain http says so rather than
    // leaving the button looking broken.
    if (!navigator.clipboard) {
      this.report(this.failureValue, FAILURE_ICON);
      return;
    }

    navigator.clipboard.writeText(this.textValue)
      .then(() => this.report(this.confirmationValue, SUCCESS_ICON))
      .catch(() => this.report(this.failureValue, FAILURE_ICON));
  }

  report(message, icon) {
    if (this.hasStatusTarget) {
      this.statusTarget.textContent = message;
    }
    if (!this.hasIconTarget) return;

    clearTimeout(this.timeout);
    this.iconTarget.classList.replace(this.restingIconValue, icon);
    this.timeout = setTimeout(() => {
      this.iconTarget.classList.replace(icon, this.restingIconValue);
    }, FEEDBACK_DURATION);
  }

  disconnect() {
    clearTimeout(this.timeout);
  }
}
