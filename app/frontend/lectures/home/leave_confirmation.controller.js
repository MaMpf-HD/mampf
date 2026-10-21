import { Controller } from "@hotwired/stimulus";

/**
 * Enables leaving a course only once the student has typed its short title,
 * so the button cannot be pressed in passing. Compares by the rule of
 * Rosters::LectureLeave.normalize, which the server applies again.
 */
export default class extends Controller {
  static targets = ["input", "submit"];
  static values = { code: String };

  connect() {
    this.check();
  }

  check() {
    const typed = this.inputTarget.value.replace(/\s+/g, "").toLowerCase();
    this.submitTarget.disabled = typed !== this.codeValue.toLowerCase();
  }
}
