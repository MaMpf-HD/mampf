import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["percentageInput", "absoluteInput", "noneHint"];

  connect() {
    this.toggle();
  }

  toggle() {
    const selected = this.element.querySelector(
      "input[name='rule[threshold_mode]']:checked",
    )?.value;

    this.percentageInputTarget.hidden = selected !== "percentage";
    this.absoluteInputTarget.hidden = selected !== "absolute";
    this.noneHintTarget.hidden = selected !== "none";
  }
}
