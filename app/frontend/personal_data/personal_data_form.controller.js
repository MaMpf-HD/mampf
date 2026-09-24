import { Controller } from "@hotwired/stimulus";

/**
 * Shows what belongs to the answer picked and walks through the open fields
 * one step at a time, starting on the first step the server found an error in.
 */
export default class extends Controller {
  static targets = [
    "choice", "yes", "no", "answered", "step", "summary",
    "matriculationNumber", "noMatriculationNumber",
  ];

  static values = { noMatriculationNumber: String };

  connect() {
    const invalid = this.stepTargets.findIndex(step => step.querySelector(".is-invalid"));
    this.index = Math.max(invalid, 0);
    this.requireMatriculationNumber();
    this.show();
  }

  show() {
    const chosen = this.hasChoiceTarget
      ? this.choiceTargets.find(choice => choice.checked)?.value
      : "yes";
    const lastStep = this.index === this.stepTargets.length - 1;
    const stepsDone = !this.hasStepTarget || lastStep;

    for (const target of this.yesTargets) target.hidden = chosen !== "yes";
    for (const target of this.noTargets) target.hidden = chosen !== "no";
    for (const target of this.answeredTargets) {
      target.hidden = chosen === undefined || (chosen === "yes" && !stepsDone);
    }
    for (const [index, step] of this.stepTargets.entries()) step.hidden = index !== this.index;
    if (this.hasStepTarget && lastStep) this.summarize();
  }

  next(event) {
    if (event.type === "keydown" && !(event.target instanceof HTMLInputElement)) return;

    event.preventDefault();
    const fields = this.stepTargets[this.index].querySelectorAll("input:not([type=hidden])");
    if (![...fields].every(field => field.reportValidity())) return;

    this.moveTo(this.index + 1);
  }

  back() {
    this.moveTo(this.index - 1);
  }

  change({ params: { step } }) {
    this.moveTo(step);
  }

  moveTo(index) {
    this.index = index;
    this.show();
    this.stepTargets[index].querySelector("h3").focus();
  }

  requireMatriculationNumber() {
    if (!this.hasNoMatriculationNumberTarget) return;

    this.matriculationNumberTarget.required = !this.noMatriculationNumberTarget.checked;
  }

  /** Copies what the steps before hold into the check, leaving saved values. */
  summarize() {
    for (const summary of this.summaryTargets) {
      const field = this.element.querySelector(`input[name="user[${summary.dataset.field}]"]`);
      if (!field || field.disabled) continue;

      summary.textContent = field.value.trim() || "–";
    }
    if (this.hasNoMatriculationNumberTarget && this.noMatriculationNumberTarget.checked) {
      const summary = this.summaryTargets
        .find(target => target.dataset.field === "matriculation_number");
      summary.textContent = this.noMatriculationNumberValue;
    }
  }
}
