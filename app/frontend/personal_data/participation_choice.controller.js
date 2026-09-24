import { Controller } from "@hotwired/stimulus";

/** Shows the form for the answer picked; without it both stay visible. */
export default class extends Controller {
  static targets = ["choice", "yes", "no", "answered"];

  connect() {
    this.show();
  }

  show() {
    const chosen = this.choiceTargets.find(choice => choice.checked)?.value;
    for (const target of this.yesTargets) target.hidden = chosen !== "yes";
    for (const target of this.noTargets) target.hidden = chosen !== "no";
    for (const target of this.answeredTargets) target.hidden = !chosen;
  }
}
