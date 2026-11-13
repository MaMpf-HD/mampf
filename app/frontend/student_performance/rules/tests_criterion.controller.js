import { Controller } from "@hotwired/stimulus";

/**
 * Warns while the rule form asks for more passed tests than carry a passing
 * threshold. Only a warning: thresholds are often set after the rule, so the
 * form still saves.
 */
export default class extends Controller {
  static targets = ["input", "warning"];
  static values = { passFail: Number };

  connect() {
    this.check();
  }

  check() {
    const asked = Number.parseInt(this.inputTarget.value, 10);
    this.warningTarget.hidden = !(asked > this.passFailValue);
  }
}
