import { Controller } from "@hotwired/stimulus";

// The rows ticked for a hand-in on paper and the one button that records
// them. Rows come and go with every answer, so the button follows the ticks.
export default class extends Controller {
  static targets = ["checkbox", "button"];

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
    this.buttonTarget.disabled = !this.checkboxTargets.some(box => box.checked);
  }
}
