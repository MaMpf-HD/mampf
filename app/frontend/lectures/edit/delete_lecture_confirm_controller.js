import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["input", "submit"];
  static values = { expected: String };

  connect() { this.check(); }

  check() {
    this.submitTarget.disabled
      = this.inputTarget.value.trim() !== this.expectedValue.trim();
  }

  reset() {
    this.inputTarget.value = "";
    this.check();
  }
}
