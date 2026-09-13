import { Controller } from "@hotwired/stimulus";

// The rows ticked for a hand-in on paper and the one button that records
// them. Rows come and go with every answer, so the button follows the ticks.
export default class extends Controller {
  static targets = ["checkbox", "button", "count"];

  checkboxTargetConnected() {
    this.sync();
  }

  checkboxTargetDisconnected() {
    this.sync();
  }

  sync() {
    if (!this.hasButtonTarget) {
      return;
    }
    const selected = this.checkboxTargets.filter(box => box.checked).length;
    this.buttonTarget.hidden = selected === 0;
    if (this.hasCountTarget) {
      this.countTarget.textContent = selected;
    }
  }
}
