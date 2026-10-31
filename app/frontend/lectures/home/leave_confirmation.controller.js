import { Controller } from "@hotwired/stimulus";

/**
 * Enables leaving a course only once the student has typed the confirmation
 * word, so the button cannot be pressed in passing.
 */
export default class extends Controller {
  static targets = ["input", "submit"];
  static values = { word: String };

  connect() {
    this.check();
  }

  check() {
    this.submitTarget.disabled = this.inputTarget.value.trim() !== this.wordValue;
  }
}
