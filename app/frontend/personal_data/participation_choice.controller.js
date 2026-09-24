import { Controller } from "@hotwired/stimulus";

/** Shows the form for the answer picked; without it both stay visible. */
export default class extends Controller {
  static targets = ["choice", "yes", "no"];

  connect() {
    this.show();
  }

  show() {
    const chosen = this.choiceTargets.find(choice => choice.checked)?.value;
    this.yesTarget.hidden = chosen !== "yes";
    this.noTarget.hidden = chosen !== "no";
  }
}
