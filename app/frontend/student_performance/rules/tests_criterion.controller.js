import { Controller } from "@hotwired/stimulus";

/**
 * Warns while the rule form asks for more passed tests than the lecture has
 * tests with a passing threshold: nobody could meet such a rule.
 */
export default class extends Controller {
  static targets = ["input", "warning"];
  static values = { judged: Number };

  connect() {
    this.check();
  }

  check() {
    const asked = Number.parseInt(this.inputTarget.value, 10);
    this.warningTarget.hidden = !(asked > this.judgedValue);
  }
}
