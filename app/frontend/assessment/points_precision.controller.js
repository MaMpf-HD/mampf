import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["input", "warning"];

  check() {
    const value = this.inputTarget.value;

    if (!value) {
      this.hideWarning();
      return;
    }

    const normalized = value.replace(",", ".");
    const parts = normalized.split(".");
    const decimals = parts[1] || "";

    if (decimals.length > 2) {
      this.showWarning();
    }
    else {
      this.hideWarning();
    }
  }

  showWarning() {
    this.warningTarget.classList.remove("d-none");
  }

  hideWarning() {
    this.warningTarget.classList.add("d-none");
  }
}
