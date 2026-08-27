import { Controller } from "@hotwired/stimulus";

const CONFIRMATION_DURATION = 1500;

export default class extends Controller {
  static targets = ["icon", "status"];
  static values = { text: String, confirmation: String };

  copy(event) {
    event.preventDefault();

    if (!navigator.clipboard) {
      console.warn("No clipboard available; the page needs a secure context.");
      return;
    }

    navigator.clipboard.writeText(this.textValue).then(() => this.confirm());
  }

  confirm() {
    if (this.hasStatusTarget) {
      this.statusTarget.textContent = this.confirmationValue;
    }
    if (!this.hasIconTarget) return;

    clearTimeout(this.timeout);
    this.iconTarget.classList.replace("bi-envelope", "bi-check2");
    this.timeout = setTimeout(() => {
      this.iconTarget.classList.replace("bi-check2", "bi-envelope");
    }, CONFIRMATION_DURATION);
  }

  disconnect() {
    clearTimeout(this.timeout);
  }
}
