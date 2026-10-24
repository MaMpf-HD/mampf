import { Controller } from "@hotwired/stimulus";

/**
 * Enables leaving a course only once the student has typed its short title,
 * so the button cannot be pressed in passing. Compares by the rule of
 * Rosters::LectureLeave.normalize, which the server applies again.
 */
const SPACES = /[\t\n\v\f\r \u0085\u00A0\u1680\u2000-\u200A\u2028\u2029\u202F\u205F\u3000\uFEFF]+/g;

function normalize(text) {
  return text.replace(SPACES, "").toUpperCase();
}

export default class extends Controller {
  static targets = ["input", "submit"];
  static values = { code: String };

  connect() {
    this.check();
  }

  check() {
    this.submitTarget.disabled = normalize(this.inputTarget.value) !== normalize(this.codeValue);
  }
}
